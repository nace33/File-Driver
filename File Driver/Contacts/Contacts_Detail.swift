//
//  Contacts_Detail.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import SwiftUI

struct Contacts_Detail: View {
    @Environment(ContactsDelegate.self) var delegate
    var body: some View {
        Group {
            if let id = delegate.selectedID, let contact = delegate[id] {
                ContactView(contact: contact, sheets: Contact.Sheet.allCases)
            } else {
                ContentUnavailableView("No Contact Selected", systemImage:Sidebar_Item.Category.contacts.iconString)
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    Contacts_Detail()
}
