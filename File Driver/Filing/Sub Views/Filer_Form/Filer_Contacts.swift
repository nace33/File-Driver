//
//  Filer_Contacts.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/23/25.
//

import SwiftUI
import BOF_SecretSauce

struct Filer_Contacts: View {
    @Environment(Filer_Delegate.self) var delegate
    @State private var contactText  = ""
    @AppStorage(BOF_Settings.Key.filingFormContactMatch.rawValue)          var allowContactMatch   : Bool = true

    
    var body: some View {
        let eligible = delegate.selectedCase?.contacts ?? []
        
        Section {
            FormTokensPicker(title: "Contacts", items: Bindable(delegate).contacts, allItems:eligible, titleKey: \.name, altColor:.orange, create:  { createString in
               addNewFilingContact(createString)
            })
        }
            .task(id:delegate.items) {
                loadFilerItemContacts()
            }
            .onChange(of: allowContactMatch) { oldValue, newValue in
                loadFilerItemContacts()
            }
    }
    
   
}


//MARK- Load
fileprivate extension Filer_Contacts {
    //Found in Filer_Item
    func loadFilerItemContacts() {
        delegate.contacts.removeAll()
        delegate.contactData.removeAll()
        
        guard allowContactMatch else { return }
       

        var people = Set<EmailThread.Person>()
        for item in delegate.items {
            if let thread = item.emailThread {
                people.formUnion(thread.people)
            }
        }
    
        //Load people in the thread
        let existingContacts  = delegate.selectedCase?.contacts ?? []
        let existingEmailData = delegate.selectedCase?.contactData.filter({$0.category == "email"}) ?? []
        for person in people {
            if let emailFound = existingEmailData.first(where: {$0.value.lowercased() == person.email.lowercased()}) {
                if let contactFound = existingContacts.first(where: {$0.id == emailFound.contactID}) {
//                    print("Found Email and Contact")
                    //email and contact found
                    addFilingContact(contactFound)
                    addContactData(emailFound)
                } else { //email found, but no contact
//                    print("Found Email")
                    //create contact with ID matching what was in the email.
                    //this likely the contactRow in the spreadsheeet has been edited since the email row could not have been created without a contactID to reference
                    let newContact = Case.Contact(id: emailFound.contactID, centralID: nil, folderID: nil, name: person.name, role: nil, isClient: false, note: nil)
                    addFilingContact(newContact)
                    addContactData(emailFound)
                }
            }
            else if let contactFound = existingContacts.first(where: {$0.name.lowercased() == person.name.lowercased() }) {
//                print("Found Contact")
                //email not found, but contact found
                let newData    = Case.ContactData(id: UUID().uuidString, contactID: contactFound.id, category:"email", label: "Home", value: person.email, note:nil)
                addContactData(newData)
                addFilingContact(contactFound)
            }
            else {//email and contact not found
//                print("Make new Contact")
                var name = person.name.isEmpty ? person.email : person.name
                if name.isValidEmail, let prefix = name.split(separator: "@").first {
                    name = String(prefix)
                }
                let newContact = addNewFilingContact(name)
                let newData    = Case.ContactData(id: UUID().uuidString, contactID: newContact.id, category:"email", label: "Home", value: person.email, note:nil)
                addContactData(newData)
                addFilingContact(newContact)
            }
        }
        
        //Current policy is to not match names found in the Filer_Item.filename and emailThread.subject strings
        //This is because it is far less reliable to be accurate as precise email and names coming from the EmailThread
    }
    
    //Contacts
    func addNewFilingContact(_ name:String) -> Case.Contact {
        if let existing = delegate.selectedCase?.contacts.first(where: {$0.name.lowercased() == name.lowercased()}) {
            addFilingContact(existing)
            return existing
        } else {
            let newContact = Case.Contact(name: name)
            addFilingContact(newContact)
            return newContact
        }
    }
    func addFilingContact(_ contact:Case.Contact) {
        if !delegate.contacts.contains(where: {$0.id == contact.id }) {
            delegate.contacts.append(contact)
        }
    }
    func addContactData(_ data:Case.ContactData) {
        //Filer_Delegate removes contactData that already exists in the spreadsheet
        //Add the data anyway so that SwiftData model adds the relationships correctly.
        if !delegate.contactData.contains(where: {$0.id == data.id }) {
            delegate.contactData.append(data)
        }
    }
}

#Preview {
    Form {
        Filer_Contacts()
    }
        .formStyle(.grouped)
        .environment(Filer_Delegate())
}
