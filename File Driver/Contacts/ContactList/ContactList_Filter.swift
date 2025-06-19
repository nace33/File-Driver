//
//  ContactList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/13/25.
//

import SwiftUI


struct ContactList_Filter : View {
    let count : Int
    @State private var isExpanded = false
    @State private var isInside = false
    @AppStorage(BOF_Settings.Key.contactsShowColorsKey.rawValue)  var showColors  : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowVisibleKey.rawValue) var showVisible : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowHiddenKey.rawValue)  var showHidden  : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowPurgeKey.rawValue)   var showPurge   : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowImage.rawValue)      var showImage   : Bool = true
    @AppStorage(BOF_Settings.Key.contactsSortKey.rawValue)        var sortBy      : Contact.Sort = .lastName
    @AppStorage(BOF_Settings.Key.contactsLastNameFirst.rawValue)  var lastNameIsFirst  : Bool = true
    var body: some View {
        Filter_Footer(count: count, title: "Contacts") {
            LabeledContent("Show") {
                Toggle(isOn: $showVisible) { Text("Active").foregroundStyle(.green)}.padding(.trailing, 8)
                Toggle(isOn: $showHidden)  { Text("Hidden").foregroundStyle(.orange)}.padding(.trailing, 8)
                Toggle(isOn: $showPurge)   { Text("Deleted").foregroundStyle(.red)}
            }
            Toggle(isOn: $showColors)  { Text("Colors In Name")}
            Toggle(isOn: $showImage)  { Text("Profile Image")}
            
            Picker("Group By", selection:$sortBy) {
                ForEach(Contact.Sort.allCases, id:\.self) {sort in
                    Text(sort.title)
                }
            }
                .fixedSize()
                .padding(.vertical, 8)

            Picker("Display", selection:$lastNameIsFirst) {
                Text("First Name First").tag(false)
                Text("Last Name First").tag(true)
            }
                .fixedSize()
        }
    }
}
