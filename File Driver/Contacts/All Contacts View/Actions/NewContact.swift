//
//  NewContact.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/12/25.
//

import SwiftUI

struct NewContact: View {
    @State private var contact = Contact.new()
    @Environment(ContactsDelegate.self) var delegate
    @FocusState private var isFocused: Bool
    let created : (Contact) -> Void
    @AppStorage(BOF_Settings.Key.contactsDriveID.rawValue)  var driveID : String = ""
    var body: some View {
        if driveID.isEmpty {
            DriveSelector("Select a Default Contacts Drive", showCancelButton: true, canLoadFolders: false, mimeTypes: [.folder]) { self.driveID = $0.id; return false }
        } else {
          EditForm(title: "New Contact", prompt:"Create", item: $contact) { editItem in
              TextField("First Name", text:editItem.label.firstName, prompt:Text("enter first name"))
                  .focused($isFocused)
              
              TextField("Last Name", text:editItem.label.lastName, prompt:Text("enter last name"))
              
              TextField_Suggestions("Group", text:editItem.label.groupName, prompt: Text("enter group name"),  suggestions: delegate.groups)
              
          } update: { editItem in
              let newContact = try await delegate.create(contact: editItem.wrappedValue)
              self.created(newContact)
          }
          .onAppear() {
              isFocused = true
          }
      }
    }
}

