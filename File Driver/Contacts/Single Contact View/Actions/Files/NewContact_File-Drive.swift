//
//  NewContact_File-Drive.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/12/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct NewContact_File_Drive: View {
    @Bindable var contact: Contact
    @State private var path = NavigationPath()
    @State private var selectedFile : GTLRDrive_File?
    @State private var contactFile  = Contact.File.new(url:URL(string: "about:blank")!)
    @Environment(\.dismiss) var dismiss
    @State private var isUpdating = false
    
    @Environment(ContactDelegate.self) var delegate

    var body: some View {
        VStack(spacing:0) {
            if let file = selectedFile {
                EditForm(prompt: "Add", item: $contactFile) {
                    headerView
                } content: { editItem in
                    formView(editItem, file: file)
                } canUpdate: { editItem in
                    canCreateFile(editItem)
                } update: { editItem in
                    try await delegate.create(editItem)
                    dismiss()
                }
            }
            else {
                Text("Drive Navigator Here")
//
//                Drive_Selector(mimeTypes: GTLRDrive_File.MimeType.allTypesExceptFolder, select:  { selected in
//                    selectedFile = selected.isFolder ? nil : selected
//                    if let selectedFile {
//                        path.append(selectedFile)
//                    }
//                })
            }
        }            .frame(height: 440)
    }

}

//MARK: - Computed Properties
extension NewContact_File_Drive {
    
}



//MARK: - Actions
extension NewContact_File_Drive {
    func canCreateFile(_ editItem:Binding<Contact.File>) -> Bool {
        guard !editItem.wrappedValue.filename.isEmpty else { return false}
        guard !editItem.wrappedValue.category.isEmpty else { return false}
        return true
    }
    func update(_ editItem:Binding<Contact.File>, file:GTLRDrive_File) {
        editItem.wrappedValue.filename = file.title
        editItem.wrappedValue.fileID   = file.id
        editItem.wrappedValue.mimeType = file.mime.rawValue
        if let num = file.size {
            editItem.wrappedValue.fileSize = Int(num.intValue).fileSizeString
        } else {
            editItem.wrappedValue.fileSize = "unknown"
        }
    }
}

//MARK: - View Builders
extension NewContact_File_Drive {
    @ViewBuilder var headerView : some View {
        HStack {
            Button { selectedFile = nil } label : { Image(systemName: "chevron.left")}
            Text("Add File - \(contact.label.name)")
                .font(.title2)
        }
    }
    @ViewBuilder func formView(_ editItem:Binding<Contact.File>, file:GTLRDrive_File) -> some View {
        Section {
            TextField_Suggestions("Category", text:editItem.category, prompt:Text("Enter file category"), suggestions: contact.fileCategories)

            TextField("Filename", text: editItem.filename, prompt: Text("Enter filename"))
        } footer: {
            thumbnailView(file)
        }
        .onAppear() {
            update(editItem, file: file)
        }
    }
    @ViewBuilder func thumbnailView(_ file:GTLRDrive_File) -> some View {
        HStack {
            Spacer()
            AsyncImage(url:file.thumbnailURL)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Spacer()
        }
    }
}
