//
//  NewContact_File.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/13/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

struct NewContact_File: View {
    @Bindable var contact: Contact
    let category : String?
    init(contact: Contact, category: String? = nil, localURL: Contact.File.LocalURL? = nil) {
        self.contact = contact
        self.category = category
        _localURL = State(initialValue: localURL)
        _showFileImport = State(initialValue: localURL == nil)
    }
    
    @State private var contactFile  = Contact.File.new(url:URL(string: "about:blank")!)
    @Environment(\.dismiss) var dismiss
    @State private var localURL        : Contact.File.LocalURL?
    @State private var error          : Error?
    @State private var showFileImport: Bool
    @Environment(ContactDelegate.self) var delegate

    var body: some View {
        VStack {
            if let localURL = localURL {
                formView(localURL: localURL)
            } else if showFileImport {
                ProgressView()
            } else {
                Text("Canceling ...")
                    .onAppear() { dismiss() }
            }
        }
            .fileImporter(isPresented: $showFileImport, allowedContentTypes: Contact.File.urlTypes) { result in
                switch result {
                case .success(let success):
                    success.stopAccessingSecurityScopedResource()
                    self.localURL = .init(url: success)
                    success.stopAccessingSecurityScopedResource()
                case .failure(let failure):
                    self.error = failure
                }
            }
    }
}


//MARK: - Computed Variables
extension NewContact_File {
    func canCreateFile(_ editItem:Binding<Contact.File>) -> Bool {
        guard !editItem.wrappedValue.filename.isEmpty else { return false}
        guard !editItem.wrappedValue.category.isEmpty else { return false}
        return true
    }
}


//MARK: - Actions
extension NewContact_File {
    func update(_ editItem:Binding<Contact.File>, lcoalURL:Contact.File.LocalURL) {
        editItem.wrappedValue.category = self.category ?? ""
        editItem.wrappedValue.filename = lcoalURL.url.deletingPathExtension().lastPathComponent
    }
}


//MARK: - View Builders
extension NewContact_File {
    @ViewBuilder func formView(localURL:Contact.File.LocalURL) -> some View {
        EditForm(title: "Import File - \(contact.label.name)", prompt: "Add", item: $contactFile) { editItem in
            Section {
                TextField_Suggestions("Category", text:editItem.category, prompt:Text("Enter file category"),  suggestions: contact.fileCategories)

                TextField("Filename", text: editItem.filename, prompt: Text("Enter filename"))
            } footer: {
                thumbnailView(localURL.url)
            }
                .onAppear() {
                    update(editItem, lcoalURL: localURL)
                }
        } canUpdate: { editItem in
            canCreateFile(editItem)
        } update: { editItem in
            try await delegate.create(editItem, upload: localURL)
        }
    }
    @ViewBuilder func thumbnailView(_ url:URL) -> some View {
        HStack {
            Spacer()
            #if os(macOS)
            QL_View(fileURL: url)
                .frame(width:300, height:300)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.bottom)
            #else
            Web_FileView(fileURL: url, drawBackground: false)
                .frame(width:300, height:300)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.bottom)
            #endif
            Spacer()
        }

    }
}
