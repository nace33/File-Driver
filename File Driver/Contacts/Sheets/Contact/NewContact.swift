//
//  NewContact.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/12/25.
//

import SwiftUI

struct NewContact: View {
    @State private var contact = Contact.new()
    @Environment(ContactsController.self) var controller
    @FocusState private var isFocused: Bool

    var body: some View {
        EditForm(title: "New Contact", prompt:"Create", item: $contact) { editItem in
            TextField("First Name", text:editItem.label.firstName, prompt:Text("enter first name"))
                .focused($isFocused)

            TextField("Last Name", text:editItem.label.lastName, prompt:Text("enter last name"))
            
            TextField_Suggestions("Group", text:editItem.label.groupName, prompt: Text("enter group name"),  suggestions: controller.groups)

        } update: { newContact in
            _ = try await controller.create(contact: newContact.wrappedValue)
        }
            .onAppear() {
                isFocused = true
            }
    }
}

