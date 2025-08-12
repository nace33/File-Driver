//
//  ContactsView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/10/25.
//

import SwiftUI
import BOF_SecretSauce

struct Contacts_Content: View {
    @Environment(ContactsDelegate.self) var delegate
    @State private var showNewContact = false
    @State private var editContact : Contact?
    var body: some View {
        VStackLoacker(loader: Bindable(delegate).loader) {
            ContactsList(showFilter:true)
                .contextMenu(forSelectionType: Contact.ID.self, menu: {menu($0)}, primaryAction: {doubleClick($0)})
                .searchable(text:   Bindable(delegate).filter.string,
                            tokens: Bindable(delegate).filter.tokens,
                            placement:.toolbar,
                            prompt: Text("Type to filter, or use #, $ for tags")) { token in
                    Text(token.title)
                }
                .searchSuggestions { delegate.filter.searchSuggestions }
        }
            .frame(minWidth:300, idealWidth: 400)
            .sheet(isPresented: $showNewContact) { NewContact() { _ in } }
            .sheet(item: $editContact) {editContactView($0)}
            .inspector(isPresented: .constant(true)) {
                Contacts_Detail()
                    .inspectorColumnWidth(min: 500, ideal: 500)
            }
            .toolbar { toolbarView    }
            .task { await delegate.loadContacts()}
    }
    

    func doubleClick(_ ids:Set<Contact.ID>) {
        guard let id = ids.first else { return }
        editContact = delegate.contacts.first(where: { $0.id == id })
    }
}



//MARK: - VIew Builders
extension Contacts_Content {
    @ViewBuilder func menu(_ ids:Set<Contact.ID>) -> some View {
        if ids.count == 1, let id = ids.first, let con = delegate[id] {
            Button("Edit") { editContact = con.wrappedValue }
            Divider()
        }
        ContactsFilter(style:.menu)
    }
    @ViewBuilder func editContactView(_ editContact:Contact) -> some View {
        if let con = delegate[editContact.id] { EditContact(contact: con)
        } else {  Button("Ooopsies!") { self.editContact = nil}.padding(100)   }
    }

    @ToolbarContentBuilder var toolbarView : some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button("New")  { showNewContact.toggle() }
            Button("Edit") { editContact = delegate[delegate.selectedID]?.wrappedValue }
                .disabled(delegate.selectedID == nil )
        }
    }
}


//MARK: - Preview
#Preview {
    Contacts_Content()
        .environment(ContactsDelegate())
}
