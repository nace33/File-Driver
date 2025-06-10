//
//  Contacts_List.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce


struct Contacts_List: View {
    @State private var controller = NLF_ContactsController()
    @State private var showNewContactSheet: Bool = false
    
    enum GroupBy : String, CaseIterable { case firstName, lastName, group, visiblity, client}
    @AppStorage(BOF_Settings.Key.contactsGroupKey.rawValue) var groupBy : GroupBy = .lastName

    @AppStorage(BOF_Settings.Key.contactsShowVisibleKey.rawValue) var showVisible : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowHiddenKey.rawValue)  var showHidden  : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowPurgeKey.rawValue)   var showPurged  : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowColorsKey.rawValue)  var showColors  : Bool = true

    var body: some View {
        VStackLoader(title: "", isLoading: $controller.isLoading, status: $controller.loadStatus, error: $controller.error) {
            if controller.contacts.isEmpty { Text("No Contacts").foregroundStyle(.secondary)}
            else {
                HSplitView {
                    listView
                        .frame(minWidth:300, idealWidth: 400, maxWidth: 500)
                    if controller.selection.count == 1,
                        let selected = controller.selectedContacts.first,
                        let index = controller.index(of: selected) {
                        NLF_Contact_View($controller.contacts[index])
                            .frame(maxWidth: .infinity, maxHeight:.infinity)
                            .layoutPriority(1)
                    } else if controller.selection.count > 1 {
                        multipleSelection
                            .frame(maxWidth: .infinity, maxHeight:.infinity)
                            .layoutPriority(1)
                    }
                    else {
                        ContentUnavailableView("No Selection", systemImage: "filemenu.and.selection", description: Text("Select a contact from the list on the left."))
                            .frame(maxWidth: .infinity, maxHeight:.infinity)
                            .layoutPriority(1)
                    }
                }
            }
        }
            .task { await controller.load()}
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("New") { showNewContactSheet.toggle() }
                }
            }
            .sheet(isPresented: $showNewContactSheet) { NLF_Contact_New() }
            .environment(controller)
    }
  
    @ViewBuilder var multipleSelection : some View {
        Text("Too many selected Jimbo")
    }
}


//MARK: - ViewBuilders
///Lists
fileprivate extension Contacts_List {
    @ViewBuilder var listView: some View {
        VStack(alignment: .leading, spacing: 0) {
            let contacts = controller.filteredContacts(showVisible: showVisible, showHidden: showHidden, showPurged: showPurged)
            List(selection:$controller.selection) {
                list(contacts)
            }
                .listStyle(.sidebar)
                .contextMenu { listMenu }
                .searchable(text:   $controller.filter.string,
                            tokens: $controller.filter.tokens,
                            placement: .sidebar,
                            prompt: Text("Type to filter, or use # for tags")) { token in
                                Text(token.title)
                            }
                .searchSuggestions { controller.filter.searchSuggestions }
            
            Contacts_List_Filter(count: contacts.count)
                .padding(.bottom, 8)
        }
    }
    @ViewBuilder func list(_ contacts:[NLF_Contact]) -> some View {
        switch groupBy {
        case .firstName, .lastName:
            alphaSectionHeaders(contacts)
        case .group:
            groupHeaders(contacts)
        case .visiblity:
            visibilityHeaders(contacts)
        case .client:
            clientHeaders(contacts)
        }
    }
    var key: KeyPath<NLF_Contact, String> {
        if groupBy == .firstName { \.label.name }
        else {  \.label.nameReversed }
    }
    @ViewBuilder func alphaSectionHeaders(_ contacts:[NLF_Contact]) -> some View {
        BOFSections(of: contacts, groupedBy: key, isAlphabetic: true) { headerText in
            Text(headerText)
        } row: { contact in
            contactRow(contact)
        }
            .listRowSeparator(.hidden)
    }
    @ViewBuilder func groupHeaders(_ contacts:[NLF_Contact]) -> some View {
        BOFSections(of: contacts, groupedBy: \.label.groupName, isAlphabetic: false) { headerText in
            Text(headerText.isEmpty ? "No Group".uppercased() : headerText.uppercased())
        } row: { contact in
            contactRow(contact)
        }
            .listRowSeparator(.hidden)
    }
    @ViewBuilder func visibilityHeaders(_ contacts:[NLF_Contact]) -> some View {
        BOFSections(of: contacts, groupedBy: \.label.status.title, isAlphabetic: false) { headerText in
            Text(headerText.isEmpty ? "No Status".uppercased() : headerText.uppercased())
                .foregroundStyle(NLF_Contact.DriveLabel.Status.color(headerText, isHeader: true))
        } row: { contact in
            contactRow(contact)
        }
            .listRowSeparator(.hidden)
    }
    @ViewBuilder func clientHeaders(_ contacts:[NLF_Contact]) -> some View {
        BOFSections(of: contacts, groupedBy: \.label.client.title, isAlphabetic: false) { headerText in
            Text(headerText.isEmpty ? "No Client Status".uppercased() : headerText.uppercased())
        } row: { contact in
            contactRow(contact)
        }
            .listRowSeparator(.hidden)
    }
    @ViewBuilder var listMenu : some View {
        Picker("Sort By", selection: $groupBy) { ForEach(GroupBy.allCases, id:\.self) { Text($0.rawValue.camelCaseToWords())}}
        Menu("Show") {
            Toggle(isOn: $showVisible) {
                Text("Active")
                    .foregroundStyle(NLF_Contact.DriveLabel.Status.active.color(isHeader: true))
            }
            Toggle(isOn: $showHidden) {
                Text("Hidden")
                    .foregroundStyle(NLF_Contact.DriveLabel.Status.hidden.color())
            }
            Toggle(isOn: $showPurged) {
                Text("Purge")
                    .foregroundStyle(NLF_Contact.DriveLabel.Status.purge.color())
            }
            Divider()
            Toggle(isOn: $showColors) {
                Text("Status Colors")
            }
        }
    }
    
    @ViewBuilder func contactRow(_ contact:NLF_Contact) -> some View {
        switch groupBy {
        case .visiblity:
            Text(contact.label.nameReversed)
                .contextMenu { menu(contact)}
        default:
            Text(groupBy == .firstName ? contact.label.name : contact.label.nameReversed)
                .foregroundStyle(showColors ? contact.label.status.color() : .primary)
                .contextMenu { menu(contact)}
        }
    }
    @ViewBuilder func menu(_ contact:NLF_Contact) -> some View {
        Text("Group:\t \(contact.label.groupName.isEmpty ? "None" : contact.label.groupName)")
            .modifierKeyAlternate(.command) {
                Button("Show in Drive") { File_DriverApp.createWebViewTab(url: contact.file.showInDriveURL, title: contact.name)}
            }
        Text("Used:\t \(contact.label.timesUsed) times")
            .modifierKeyAlternate(.command) {
                Button("Edit in Google Sheets") { File_DriverApp.createWebViewTab(url: contact.file.editURL, title: contact.name)}
            }
        if let updated = Date.idDate(contact.label.updateID) {
            Text("Updated:\t \(updated)")
        }
    }
}


#Preview {
    Contacts_List()
        .environment(Google.shared)
        .padding()
}
