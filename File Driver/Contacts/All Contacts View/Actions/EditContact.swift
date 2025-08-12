//
//  EditContact.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/11/25.
//

import SwiftUI

struct EditContact : View {
    @Binding var contact : Contact
    init(contact: Binding<Contact>) {
        _contact = contact
        _groups = State(initialValue: ContactsDelegate.shared.groups)
        _title = State(initialValue: contact.wrappedValue.label.name)
        _originalLabel = State(initialValue: contact.wrappedValue.label)
    }
    @Environment(ContactsDelegate.self) var delegate
    @FocusState private var isFocused: Bool
    @State private var error : Error?
    @State private var groups : [String]
    @State private var title : String
    @State private var originalLabel : Contact.Label

    
    var body: some View {
        EditForm(title:"Edit - \(title)", item: $contact) { editItem in
            LabeledContent("Profile Image") {
                Drive_Imager(item:editItem.wrappedValue, placeholder: "person", canEdit: true) { newImageData in
                    if newImageData == nil {
                        editItem.wrappedValue.label.iconID = ""
                    }
                    editItem.wrappedValue.label.imageData = newImageData
                }
            }
            
            TextField("First Name", text:editItem.label.firstName, prompt:Text("enter first name"))
                .focused($isFocused)
        
            TextField("Last Name", text:editItem.label.lastName, prompt:Text("enter last name"))
            
            TextField_Suggestions("Group", text:editItem.label.groupName, prompt: Text("enter group name"), suggestions: groups)
        
            
            Picker("Status", selection:editItem.label.status) {
                ForEach(Contact.DriveLabel.Status.allCases, id:\.self) { status in
                    Text(status.title)
                        .foregroundStyle(status.color(isHeader: true))
                }
            }

            Picker("Client", selection:editItem.label.client) {
                ForEach(Contact.DriveLabel.ClientStatus.allCases, id:\.self) { status in
                    Text(status.title)
                }
            }
        } canUpdate: { editItem in
            guard !editItem.wrappedValue.label.firstName.isEmpty else { return false }
            return editItem.wrappedValue.label != originalLabel
        }
        update: { editedItem in
            try await delegate.update(editedItem)
        }
            .onAppear() {
                isFocused = true
            }
    }
    

}


#Preview {
    @Previewable @State var contact = Contact.new( firstName: "Frodo", lastName: "Baggins", groupName: "Lord of the Rings", iconID:"1xQ37nUNiW-n93m3aUxWdD_uiztP_eLx7")
    EditContact(contact:$contact)
        .environment(Google.shared)
        .environment(ContactsDelegate.shared)
}

