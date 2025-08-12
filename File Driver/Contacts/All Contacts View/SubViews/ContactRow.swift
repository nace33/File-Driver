//
//  ContactList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/13/25.
//
import SwiftUI


struct Contact_Row : View {
    @Bindable var contact : Contact
    @State private var isTargeted = false
    @State private var localURL : Contact.File.LocalURL?
    @AppStorage(BOF_Settings.Key.contactsGroupBy.rawValue) var groupBy  : Contact.Group  = .lastName
    @AppStorage(BOF_Settings.Key.contactsShow.rawValue)    var show     : [Contact.Show] = Contact.Show.allCases
    var body: some View {
        HStack {
            if show.contains(.profileImage) {
                Drive_Imager(item: contact, placeholder: "person", width: 24, height: 24, showBorder: false) { _ in }
            }
            Text(contact[keyPath: displayKey])
                .foregroundStyle(color)
        }
            .frame(maxWidth: .infinity, minHeight:24, alignment: .leading)
            .sheet(item: $localURL) { NewContact_File(contact: contact, localURL:$0)}
            .dropStyle(isTargeted:$isTargeted, style: .listRowFill, hPad:10)
            .dropDestination(for: URL.self, action: { items, location in
                guard let url = items.first else { return false }
                self.localURL = .init(url: url)
                return true
            }, isTargeted: {self.isTargeted = $0})
            .importsPDFs(directory:URL.applicationSupportDirectory, filename: "\(Date().yyyymmdd) \(contact.label.name) Scan.pdf", imported: { url in
                localURL = .init(url: url)
            })
    }
    var displayKey : KeyPath<Contact,String> {
        switch show.contains(.lastNameFirst) {
        case true:
            groupBy == .firstName ? \.label.name :  \.label.nameReversed
        case false:
            \.label.name
        }
    }
    var color : Color {
        guard show.contains(.statusColors) else { return Color.primary}
        return contact.label.status.color()
    }
}
