//
//  ContactsList2.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/10/25.
//

import SwiftUI

struct ContactsList: View {
    let showFilter :Bool
    @Environment(ContactsDelegate.self) var delegate
    @AppStorage(BOF_Settings.Key.contactsGroupBy.rawValue) var groupBy  : Contact.Group  = .lastName
    @AppStorage(BOF_Settings.Key.contactsShow.rawValue)    var show     : [Contact.Show] = Contact.Show.allCases
    
    var body: some View {
        VStack(spacing:0) {
            let filteredContacts = delegate.filteredContacts
            ScrollViewReader { proxy in
                List(selection: Bindable(delegate).selectedID) {
                    if filteredContacts.isEmpty {  noFilteredContactsView }
                    BOFBoundSections(of: filteredContacts, groupedBy: groupBy.key, isAlphabetic: groupBy.isAlphabetic) { header in
                        Text(header.isEmpty ? "No Group" : header.capitalized)
                    } row: { contact in
                        Contact_Row(contact: contact.wrappedValue)
                    }
                }
                    .onChange(of: delegate.scrollToID) { _, newID in  proxy.scrollTo(newID)  }
            }
            
            if showFilter {
                Filter_Footer(count:filteredContacts.count, title:"Contacts") {
                    ContactsFilter(style:.form)
                }
            }
        }
            //this is triggered when 'show' is changed, and casues view to update
            //checkSelection does not need to be called for the sort to occur, the view itself is beign reloaded
            .onChange(of: show) { oldValue, newValue in delegate.checkSelection()}
    }

    
    @ViewBuilder var noFilteredContactsView : some View {
        if delegate.contacts.count > 0 {
            VStack(alignment:.leading) {
                Text("No Contacts Found")
                    .foregroundStyle(.secondary)
                Text("Try changing your filter settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("No Contacts")
                .foregroundStyle(.secondary)
        }
    }


   
}
