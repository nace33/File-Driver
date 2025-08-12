//
//  ContactView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import SwiftUI

struct ContactView: View {
    @Binding var contact : Contact
    let sheets : [Contact.Sheet]
    @State private var showAddToCase    = false
    @State private var isTargeted       = false
    @State private var localURL         : Contact.File.LocalURL?
    @State private var delegate         = ContactDelegate()

    var body: some View {
        ScrollView {
            Grid(alignment:.trailing, verticalSpacing: 0) {
                Contact_Header(contact: $contact, )
                    .frame(minHeight: 75)
                
                if let error = delegate.loader.error {
                    errorGridRow(error)
                }
                else if delegate.loader.isLoading {
                    loadingGridRow
                }
                else if showNoInfoFilesOrCasesView {
                    noInfoFilesOrCasesView
                }
                else {
                    if sheets.contains(.info) {
                        Contact_Info_View(contact: $contact)
                    }
                    if sheets.contains(.files) {
                        Contact_Files_View(contact: $contact)
                    }
          
                }
            }
        }
            .frame(minWidth:400)
            .sheet(isPresented: $showAddToCase) { AddToCase_Contact(contact:contact) }
            .sheet(item: $localURL) { NewContact_File(contact: contact, localURL:$0)}
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
                    Button("Add to Case") { showAddToCase.toggle()}
                }
            }
            .task(id:contact.id) {
                self.delegate.contact = contact
                await self.delegate.load(sheets)
            }
            .environment(delegate)
    }
}
//MARK: - View Builders
extension ContactView {
    var showNoInfoFilesOrCasesView : Bool {
        var allEmpty = true
        if sheets.contains(.info), !contact.infos.isEmpty {
            allEmpty = false
        }
        if sheets.contains(.files), !contact.files.isEmpty {
            allEmpty = false
        }

    
        return allEmpty
    }
}


//MARK: - View Builders
extension ContactView {
    @ViewBuilder var loadingGridRow: some View {
        GridRow {
            Text(delegate.loader.status).foregroundStyle(.secondary)
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
                Button("Retry") { Task { await delegate.load( sheets)}}
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



#Preview {
    @Previewable @State var contact = Contact.new(status: .active, client: .notAClient, firstName: "Frodo", lastName: "Baggins", groupName: "Lord of the Rings", iconID: "", timesUsed: 0)
    ContactView(contact: $contact, sheets: Contact.Sheet.allCases)
}
