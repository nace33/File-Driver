//
//  Contact_View.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/12/25.
//

import SwiftUI

struct ContactDetail: View {
    @Environment(Contact.self) var contact
    @Environment(ContactsController.self) var controller
    let sheets : [Contact.Sheet]
    @State private var showAddToCase = false
    @State private var showEditContact = false
    @State private var isTargeted = false
    @State private var localURL        : Contact.File.LocalURL?
    
    var body: some View {
        ScrollView {
            Grid(alignment:.trailing, verticalSpacing: 0) {
                
                ContactDetail_Header()
                    .frame(minHeight: 75)
                
                if let error = contact.error {
                    errorGridRow(error)
                }
                else if contact.isLoading {
                    loadingGridRow
                }
                else if showNoInfoFilesOrCasesView {
                    noInfoFilesOrCasesView
                }
                else {
                    if sheets.contains(.info) {
                        ContactDetail_Info()
                    }
                    if sheets.contains(.files) {
                        ContactDetail_Files()
                        
                    }
                    if sheets.contains(.cases) {
                        ContactDetail_Cases()
                    }
                }
            }
        }
            .frame(minWidth:400)
            .sheet(isPresented: $showAddToCase) { AddToCase_Contact(contact:contact) }
            .sheet(item: $localURL) { NewContact_File(contact: contact, localURL:$0)}
            .sheet(isPresented: $showEditContact) {
                if let index = controller.index(of: contact) {
                    EditContact(contact: Bindable(controller).contacts[index])
                } else {
                    Button("Ooopsies!") { showEditContact.toggle()}.padding(100)
                }
            }
            .dropStyle(isTargeted:$isTargeted)
            .dropDestination(for: URL.self, action: { items, location in
                guard let url = items.first else { return false }
                self.localURL = .init(url: url)
                return true
            }, isTargeted: {self.isTargeted = $0})
            .importsPDFs(directory:URL.applicationSupportDirectory, filename: "\(Date().yyyymmdd) \(contact.label.name) Scan.pdf", imported: { url in
                localURL = .init(url: url)
            })
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Edit") { showEditContact.toggle() }
                    Button("Add to Case") { showAddToCase.toggle()}
                }
            }
            .task(id:contact.id) {
                try? await contact.load( sheets)
            }
    }
}


//MARK: - View Builders
extension ContactDetail {
    var showNoInfoFilesOrCasesView : Bool {
        var allEmpty = true
        if sheets.contains(.info), !contact.infos.isEmpty {
            allEmpty = false
        }
        if sheets.contains(.files), !contact.files.isEmpty {
            allEmpty = false
        }
        if sheets.contains(.cases), !contact.cases.isEmpty {
            allEmpty = false
        }
    
        return allEmpty
    }
}

//MARK: - View Builders
extension ContactDetail {
    @ViewBuilder var loadingGridRow: some View {
        GridRow {
            Text("Loading").foregroundStyle(.secondary)
            HStack {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width:16, height:16)
                Spacer()
            }
        }
    }
    @ViewBuilder func errorGridRow(_ error:Error) -> some View {
        GridRow {
            Text("Error").foregroundStyle(.secondary)
                
            VStack {
                Text(error.localizedDescription)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        GridRow {
            Text(" ")
            HStack {
                Button("Retry") { Task { try? await contact.load( sheets)}}
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)

                Spacer()
            }
        }
    }
    @ViewBuilder var  noInfoFilesOrCasesView : some View {
        GridRow {
            Text(" ")
            HStack {
                Text("No Contact Information")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }
}

