//
//  ContactsList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/11/25.
//

import SwiftUI
import BOF_SecretSauce
struct ContactsList : View {
    @Environment(ContactsController.self) var controller
    @State private var showNewContact = false
    @State private var editContact : Contact?
    @AppStorage(BOF_Settings.Key.contactsDriveIDKey.rawValue)     var driveID     : String = ""
    @AppStorage(BOF_Settings.Key.contactTemplateIDKey.rawValue)   var templateID  : String = ""
    @AppStorage(BOF_Settings.Key.contactsShowColorsKey.rawValue)  var showColors  : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowVisibleKey.rawValue) var showVisible : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowHiddenKey.rawValue)  var showHidden  : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowPurgeKey.rawValue)   var showPurge   : Bool = true
    @AppStorage(BOF_Settings.Key.contactsSortKey.rawValue)        var sortBy      : Contact.Sort = .lastName
    @AppStorage(BOF_Settings.Key.contactsShowImage.rawValue)      var showImage   : Bool = true
    @AppStorage(BOF_Settings.Key.contactsLastNameFirst.rawValue)  var lastNameIsFirst  : Bool = true

    @State private var driveDelegate = Google_DriveDelegate.selecter(mimeTypes: [.folder])
    
    var body: some View {
        HSplitView {
            if driveID.isEmpty {
                setDriveIDView
            }
            else if templateID.isEmpty {
                setTemplateIDView
            }
            else if controller.isLoading {
                theLoadingView
            }
            else if controller.contacts.isEmpty {
                emptyContactsView
            }
            else {
                theListView
                    .alternatingRowBackgrounds()

                    .frame(minWidth:400, idealWidth: 400, maxWidth: 400)
                    .contextMenu(forSelectionType: Contact.ID.self, menu: { menu($0) }, primaryAction: { listDoubleClick($0) })
                    .sheet(isPresented: $showNewContact) { NewContact() }
                    .sheet(item: $editContact) { editContact in
                        if let index = controller.index(of: editContact) {
                            EditContact(contact: Bindable(controller).contacts[index])
                        }else {
                            Button("Ooopsies!") { self.editContact = nil}.padding(100)
                        }
                    }
                Group {
                    if let index = controller.selectedIndex {
                        ContactDetail(sheets: [.info, .files, .cases])
                            .environment(controller.contacts[index])
                    } else {
                        ContentUnavailableView("No Selection", systemImage: "filemenu.and.selection", description: Text("Select a contact from the list on the left."))
                    }
                }
                .layoutPriority(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
            .task {
                await controller.loadContacts()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button("New") { showNewContact.toggle() }
                }
            }
    }
}

//MARK: - Computed Properties
extension ContactsList {
    var filteredContacts : [Contact] {
        let filter = controller.filter
        return controller.contacts.filter { contact in
            if !showVisible, contact.label.status == .active  { return false }
            if !showHidden,  contact.label.status == .hidden  { return false }
            if !showPurge ,  contact.label.status == .purge   { return false }
            
            
            if !filter.string.isEmpty, !filter.hasTokenPrefix, !contact.label.name.ciContain(filter.string) { return false   }
            if !filter.tokens.isEmpty {
                for token in filter.tokens {
                    if token.prefix == .dollarSign {
                        if contact.label.client.rawValue != token.rawValue { return false }
                    } else if token.prefix == .hashTag {
                        if contact.label.groupName != token.rawValue { return false }
                    }
                }
            }
            return true
        }
    }
    var sortKey : KeyPath<Contact,String> {
        switch sortBy {
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
            sortBy == .firstName ? \.label.name :  \.label.nameReversed
        case false:
            \.label.name
        }
    }
    var isAlphabetic : Bool {
        sortBy == .firstName || sortBy == .lastName
    }
}



//MARK: - Actions
extension ContactsList {
    func listDoubleClick(_ items:Set<Contact.ID>) {
        if let first = items.first, let contact = controller[first] {
            editContact = contact
        }
    }
}


//MARK: - View Builders
extension ContactsList {
    @ViewBuilder var setDriveIDView : some View {
        Google_DriveView("Select a drive to save Contacts in", delegate: $driveDelegate, canLoad: { _ in false})
            .onAppear {
                driveDelegate.mimeTypes = [.folder]
            }
            .onChange(of: driveDelegate.selectItem) { _, newValue in
                if let newValue, newValue.id == newValue.driveId {
                    self.driveID = newValue.id
                    Task { await controller.loadContacts() }
                }
            }
    }
    @ViewBuilder var setTemplateIDView : some View {
        Google_DriveView("Select a Contact Google Sheet Template", delegate: $driveDelegate, load: {
            if let last = driveDelegate.stack.last {
                try await Google_Drive.shared.getContents(of: last.id)
            } else {
                try await Google_Drive.shared.getContents(of: driveID)
            }
        })
            .onAppear {
                driveDelegate.mimeTypes = [.sheet]
            }
            .onChange(of: driveDelegate.selectItem) { _, newValue in
                if let newValue {
                    templateID = newValue.id
                    Task { await controller.loadContacts() }
                }
            }
    }
    @ViewBuilder var emptyContactsView : some View {
        VStack {
            Spacer()
            Text("No Contacts")
            Button("Create Contact") { showNewContact.toggle() }
            Spacer()
        }
    }
    @ViewBuilder var emptyFilteredContactsView : some View {
        if controller.filter.isEmpty {
            Menu {
                listOptionsButtons
            } label: {
                Text("- \(controller.contacts.count ) contacts are hidden -")
                    .foregroundStyle(.blue)
            }
                .fixedSize()
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .padding(.vertical)

        } else {
            Text("No Contacts")
                .foregroundStyle(.secondary)
                .padding(.vertical)
        }
    }
    @ViewBuilder var theLoadingView : some View {
        VStack {
            Spacer()
            ProgressView("Loading Contacts")
            Spacer()
        }
    }
    @ViewBuilder var theListView : some View {
        VStack(spacing:0) {
            let filteredContacts = filteredContacts
            ScrollViewReader { proxy in
                List(selection:Bindable(controller).selectedID) {
                    if filteredContacts.isEmpty {  emptyFilteredContactsView }
                    
                    BOFSections(of: filteredContacts, groupedBy:sortKey, isAlphabetic: isAlphabetic) { headerText in
                        Text(headerText.uppercased())
                    } row: { contact in
                        ContactList_Row(contact: contact, displayKey: displayKey)
                            .foregroundStyle(showColors ? contact.label.status.color() : Color.primary)
                        
                    }
                    .listRowSeparator(.hidden)
                    
                }
                .listStyle(.sidebar)
                .onChange(of: controller.scrollToID) { _, newID in  proxy.scrollTo(newID)  }
                .searchable(text:   Bindable(controller).filter.string,
                            tokens: Bindable(controller).filter.tokens,
                            placement:.sidebar,
                            prompt: Text("Type to filter, or use #, $ for tags")) { token in
                    Text(token.title)
                }
                .searchSuggestions { controller.filter.searchSuggestions }
            }
            ContactList_Filter(count: filteredContacts.count)
        }
    }
    @ViewBuilder func menu(_ items:Set<Contact.ID>) -> some View {
        if items.isEmpty {
            Button("New Contact") { showNewContact.toggle() }
            if let selected = controller.selected {
                Divider()
                Button("Edit \(selected.label.name)") { editContact = selected}
            }
      
            Divider()
            Menu("Show") {
                listOptionsButtons
            }
            
            Divider()
            Picker("Group By", selection:$sortBy) {
                ForEach(Contact.Sort.allCases, id:\.self) {sort in
                    Text(sort.title)
                }
            }
            Picker("Display", selection:$lastNameIsFirst) {
                Text("First Name First").tag(false)
                Text("Last Name First").tag(true)
            }
            
            if controller.filter.string.count > 0 || controller.filter.tokens.isNotEmpty {
                Divider()
                Button("Clear Filter") { controller.filter.string = ""; controller.filter.tokens = [] }
            }
        }
        else if let first = items.first, let contact = controller[first] {
            Button("Edit") { editContact = contact}
        }
    }
    @ViewBuilder var listOptionsButtons: some View {
        Toggle("Active Contacts", isOn: $showVisible)
        Toggle("Hidden Contacts", isOn: $showHidden)
        Toggle("Contacts marked for Deletion", isOn: $showPurge)
        Divider()
        Toggle("Status Colors", isOn: $showColors)
        Divider()
        Toggle(isOn: $showImage)  { Text("Profile Image")}
    }
}
