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
        let current  = delegate.contacts.compactMap({$0.name}).joined()
        let eligible = delegate.selectedCase?.contacts.filter({!current.ciContain($0.name)  }) ?? []
        Section {
            LabeledContent {
                TextField("Contacts", text:$contactText, prompt: Text("Add Contacts"))
                    .labelsHidden()
#if os(macOS)
                    .textInputSuggestions {
                        if contactText.count > 0 {
                            let matches = delegate.selectedCase?.contacts.filter({$0.name.ciHasPrefix(contactText) && !current.ciContain($0.name)  }) ?? []
                            ForEach(matches) {  Text($0.name) .textInputCompletion($0.name) }
                        }
                    }
#endif
                    .onSubmit {
                        _ = addNewFilingContact(contactText)
                        contactText = ""
                    }
            } label: {
                Menu("Contacts") {
                    if eligible.count > 10 {
                        BOFSections(.menu, of: eligible , groupedBy: \.name, isAlphabetic: true) { letter in
                            Text(letter)
                        } row: { contact in
                            Button(contact.name) { addFilingContact(contact)  }
                        }
                    } else {
                        ForEach(eligible.sorted(by: {$0.name.ciCompare($1.name)})) { contact in
                            Button(contact.name) { addFilingContact(contact)  }
                        }
                    }
                }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(eligible.isEmpty ? .hidden : .visible)
                    .labelsHidden()
                    .fixedSize()
            }

            if delegate.contacts.count > 0 {
                Flex_Stack(data: delegate.contacts, alignment: .trailing) { contact in
                    let isExisting = contactIsInSpreadsheet(contact.id)
                    Text(contact.name)
                        .tokenStyle(color:isExisting ? .blue : .orange,  style:.strike) {
                            removeFilingContact(contact.id)
                        }
                }
          
            }
        }
            .task(id:delegate.items) {
                loadFilerItemContacts()
            }
            .onChange(of: allowContactMatch) { oldValue, newValue in
                loadFilerItemContacts()
            }
    }
    
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
    func contactIsInSpreadsheet(_ id:Case.Contact.ID) -> Bool {
        //for UI
        delegate.selectedCase?.isInSpreadsheet(id, sheet: .contacts) ?? false
    }
    func addFilingContact(_ contact:Case.Contact) {
        if !delegate.contacts.contains(where: {$0.id == contact.id }) {
            delegate.contacts.append(contact)
        }
    }
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
    func removeFilingContact(_ id:Case.Contact.ID) {
        _ = delegate.contacts.remove(id:id)
        removeAllContactData(for:id)
    }
    
    //Contacts Data
    func contactDataIsInSpreadsheet(_ id:Case.ContactData.ID) -> Bool {
        //for UI
        delegate.selectedCase?.isInSpreadsheet(id, sheet: .contactData) ?? false
    }
    func addContactData(_ data:Case.ContactData) {
        //Filer_Delegate removes contactData that already exists in the spreadsheet
        //Add the data anyway so that SwiftData model adds the relationships correctly.
        if !delegate.contactData.contains(where: {$0.id == data.id }) {
            delegate.contactData.append(data)
        }
    }
    func removeContactData(_ id:String) {
        _ =  delegate.contactData.remove(id: id)
    }
    func removeAllContactData(for contactID:Case.Contact.ID) {
        delegate.contactData.removeAll(where: {$0.contactID == contactID})
    }
}


#Preview {
    Form {
        Filer_Contacts()
    }
        .formStyle(.grouped)
        .environment(Filer_Delegate())
}
