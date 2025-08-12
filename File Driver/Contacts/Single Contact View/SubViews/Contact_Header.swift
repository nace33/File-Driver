//
//  ContactHeader.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import SwiftUI

struct Contact_Header: View {
    @Binding var contact : Contact
    @State private var showInfoSheet  = false
    @State private var error : Error?
    @State private var showDriveImport = false
    @State private var showFileImport  = false
    @State private var showEditContact = false
    @Environment(ContactDelegate.self) var delegate
    var body: some View {
        GridRow {
            Drive_Imager(item: contact, placeholder: "person", width:48, height: 48) { _ in }
                .padding(.leading, 30)
                .padding(.trailing, 10)
            
            nameView
        }
            .contextMenu {
                Button("Edit") { showEditContact = true}
            }
            .sheet(isPresented: $showEditContact) {  EditContact(contact: $contact)         }
            .sheet(isPresented: $showInfoSheet)   {  NewContact_Info(contact:contact)       }
            .sheet(isPresented: $showFileImport)  {  NewContact_File(contact:contact)       }
            .sheet(isPresented: $showDriveImport) {  NewContact_File_Drive(contact:contact) }
    }
    
    
}


//MARK: - Actions
extension Contact_Header {
    func createInfo(_ category:String)  {
        Task {
            do {
                try await delegate.createInfo(category:category)
            } catch {
                self.error = error
            }
        }
    }
}



//MARK: - View Builders
extension Contact_Header  {
    @ViewBuilder var nameView: some View {
        VStack(alignment: .leading, spacing:0) {
            HStack {
                Text(contact.label.name)
                    .font(.title2)
                    .bold()

                addMenu
                Spacer()
                
            }
            .frame(maxWidth: .infinity)
            
            HStack {
                Text(contact.label.groupName.isEmpty ? "No Group" : contact.label.groupName)
                    .tokenStyle(color:.secondary, style:.stroke)
                
                Text(contact.label.client.title)
                    .tokenStyle(color:.secondary, style:.stroke)
                
                if contact.label.status != .active {
                    Text(contact.label.status.title).foregroundStyle(contact.label.status.color())
                }
                Spacer()
            }
            .font(.caption)
            .padding(.vertical, 4)
            
        }
    
    }
    @ViewBuilder var addMenu: some View {
        Menu {
            Section("Contact Info") {
                ForEach(Contact.Info.Category.main, id:\.self) { cat in
                    Button(cat.title) { createInfo(cat.title) }
                }
                Menu("Other") {
                    ForEach(Contact.Info.Category.misc, id:\.self) { cat in
                        Button(cat.title) { createInfo(cat.title) }
                    }
                    Divider()
                    Button("Custom") { showInfoSheet.toggle() }
                }
            }
            Section("Files") {
                Button("Computer")     { showFileImport = true   }
                Button("Google Drive") { showDriveImport = true  }
            }
        } label: {
            Text("Add")
                .foregroundStyle(.blue)
                .font(.subheadline)
        }
            .menuIndicator(.hidden)
            .menuStyle(.borderlessButton)
            .fixedSize()
    }
}


#Preview {
    @Previewable @State var contact = Contact.new(status: .active, client: .notAClient, firstName: "Frodo", lastName: "Baggins", groupName: "Lord of the Rings", iconID: "", timesUsed: 0)
    Contact_Header(contact: $contact)
}
