//
//  ContactList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/13/25.
//
import SwiftUI

struct ContactList_Row : View {
    @Bindable var contact : Contact
    @State private var isTargeted = false
    @State private var localURL : Contact.File.LocalURL?
    var displayKey : KeyPath<Contact, String>
    @AppStorage(BOF_Settings.Key.contactsShowImage.rawValue)  var showImage  : Bool = true
    var body: some View {
        Group {
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
}
