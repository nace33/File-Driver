//
//  Filer_ContactList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/9/25.
//

import SwiftUI
import BOF_SecretSauce

struct Filer_ContactList: View {
    @Environment(Filer_Delegate.self) var delegate
    @AppStorage(BOF_Settings.Key.contactsLastNameFirst.rawValue)  var lastNameIsFirst  : Bool = true
    @AppStorage(BOF_Settings.Key.contactsGroupBy.rawValue)        var groupBy      : Contact.Group = .lastName

    @AppStorage(BOF_Settings.Key.contactsShowImage.rawValue)      var showImage   : Bool = true


    var body: some View {
        ScrollViewReader { proxy in
            List(selection:Bindable(delegate).contactListSelection) {
                if delegate.centralContacts.isEmpty { Text("No Contacts").foregroundStyle(.secondary)  }
                BOFSections(of: filteredContacts, groupedBy: sortKey, isAlphabetic: isAlphabetic) { Text($0.capitalized) } row: { contact in
                    contactRow(contact).id(contact)
                }

             
                .listRowSeparator(.hidden)
            }
              .onChange(of: delegate.contactListScrollID) { _, newID in  proxy.scrollTo(newID)  }
              .contextMenu(forSelectionType: Contact.self, menu: { items in
                  if let item = items.first {
                      Button("Select Contact") {
                          delegate.select(item)
                      }
                  } }, primaryAction: { items in
                      if let item = items.first {
                          delegate.select(item)
                      }
                  })
        }
    }
    
    @ViewBuilder func contactRow(_ contact:Contact) -> some View {
        if showImage {
            Label {
                Text(contact[keyPath: displayKey])
                    .padding(.leading, 4)
            } icon: {
                Drive_Imager(item: contact, placeholder: "person", width: 24, height: 24, showBorder: false) { _ in }
            }
        } else {
            Text(contact[keyPath: displayKey])
        }
    }
    var filteredContacts : [Contact] {
        guard delegate.actions.contains(.filterContacts) else { return delegate.centralContacts }
        guard delegate.filterString.count > 0 else { return delegate.centralContacts }
        return delegate.centralContacts.filter { $0.label.name.ciContain(delegate.filterString)}
    }
    var sortKey : KeyPath<Contact,String> {
        switch groupBy {
        case .firstName:
            \.label.firstName
        case .lastName:
            \.label.nameReversed
        case .client:
            \.label.client.title
        case .group:
            \.label.groupName
        case .status:
            \.label.status.title
        }
    }
    var displayKey : KeyPath<Contact,String> {
        switch lastNameIsFirst {
        case true:
            groupBy == .firstName ? \.label.name :  \.label.nameReversed
        case false:
            \.label.name
        }
    }
    var isAlphabetic : Bool {
        groupBy == .firstName || groupBy == .lastName
    }
}

#Preview {
    Filer_ContactList()
}
