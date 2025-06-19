//
//  ContactDetail 2.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/12/25.
//

import SwiftUI

struct ContactDetail_Header : View {
    @Environment(Contact.self) var contact
    @Environment(ContactsController.self) var controller
    @State private var showInfoSheet  = false
    @State private var error : Error?
    @State private var showDriveImport = false
    @State private var showFileImport  = false
    @State private var showEditContact = false

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
            .sheet(isPresented: $showEditContact) {
                if let index = controller.index(of: contact) {
                    EditContact(contact: Bindable(controller).contacts[index])
                } else {
                    Button("Ooopsies!") { showEditContact.toggle()}.padding(100)
                }
            }
            .sheet(isPresented: $showInfoSheet) {
                NewContact_Info(contact:contact)
            }
            .sheet(isPresented: $showFileImport) {
                NewContact_File(contact:contact)
            }
            .sheet(isPresented: $showDriveImport) {
                NewContact_File_Drive(contact:contact)
            }
    }
}

//MARK: - Actions
extension ContactDetail_Header {
    func createInfo(_ category:String)  {
        Task {
            do {
                try await contact.createInfo(category:category)
            } catch {
                self.error = error
            }
        }
    }
}


//MARK: - View Builders
extension ContactDetail_Header  {
    @ViewBuilder var nameView: some View {
        VStack(alignment: .leading, spacing:0) {
            HStack {
                Text(contact.label.name)
                    .font(.title2)
                    .bold()

                newMenu
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
    @ViewBuilder var newMenu: some View {
        Menu {
            Text("Contact Info")
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
            Text("Files From")
            Button("Computer")     { showFileImport = true   }
            Button("Google Drive") { showDriveImport = true  }
        } label: {
            Text("New")
                .foregroundStyle(.blue)
                .font(.subheadline)
        }
            .menuIndicator(.hidden)
            .menuStyle(.borderlessButton)
            .fixedSize()
    }
}
