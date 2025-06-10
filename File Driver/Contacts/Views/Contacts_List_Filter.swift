//
//  Contacts_List_Filter.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/5/25.
//

import SwiftUI
import BOF_SecretSauce
struct Contacts_List_Filter: View {
    let count : Int
    @Environment(NLF_ContactsController.self) var controller
    @AppStorage(BOF_Settings.Key.contactsShowVisibleKey.rawValue) var showVisible : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowHiddenKey.rawValue)  var showHidden  : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowPurgeKey.rawValue)   var showPurged  : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowColorsKey.rawValue)  var showColors  : Bool = true
    @State private var isExpanded = false
    @AppStorage(BOF_Settings.Key.contactsGroupKey.rawValue) var groupBy : Contacts_List.GroupBy = .lastName
    
    var body: some View {
        VStack(spacing:0) {
            Divider()
            if isExpanded { expandedView }
            else { compactView }
        }
    }

}

//MARK: - View Builders
extension Contacts_List_Filter {
    @ViewBuilder var expandedView : some View {
        compactView
        Form {
            LabeledContent("Show") {
                VStack(alignment:.leading) {
                    HStack {
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
                    }
                    Toggle(isOn: $showColors) {
                        Text("Status Colors")
                    }
                }
            }
            
            
            Picker("Sort By", selection: $groupBy) {
                ForEach(Contacts_List.GroupBy.allCases, id:\.self) {
                    Text($0.rawValue.camelCaseToWords())
                }
            }
            .fixedSize()
            
        }
        .padding(.top, 6)
        .padding(.bottom, 8)
    }
    @ViewBuilder var compactView  : some View {
        HStack {
            let total = controller.contacts.count
            if count ==  total{
                Text("Contacts: \(count)")
            } else {
                Text("Contacts: \(count), \(total - count) filtered")
            }
            Button { isExpanded.toggle()} label: {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            }
                .buttonStyle(.plain)
        }
            .padding(.top, 8)
            .padding(.bottom, 2)
            .foregroundStyle(.secondary)
    }
}
#Preview {
    Contacts_List_Filter(count:4)
}
