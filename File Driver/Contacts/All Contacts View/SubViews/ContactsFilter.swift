//
//  ContactsFilter.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/10/25.
//

import SwiftUI

struct ContactsFilter: View {
    @Environment(ContactsDelegate.self) var delegate
    let style : Style
    enum Style { case form, menu }
    @AppStorage(BOF_Settings.Key.contactsGroupBy.rawValue)  var groupBy : Contact.Group  = .lastName
    @AppStorage(BOF_Settings.Key.contactsShow.rawValue)     var show    : [Contact.Show] = Contact.Show.allCases

    
    var body: some View {
        Group {
            switch style {
            case .form:
                LabeledContent("Show") {  VStack(alignment:.leading)    {   filterOptions  }  }
                LabeledContent("Display") {  VStack(alignment:.leading) {   displayOptions }  }
                groupByPicker
            case .menu:
                Menu("Show")    { filterOptions  }
                Menu("Display") { displayOptions }
                groupByPicker
            }
        }
            .onChange(of: groupBy) { oldValue, newValue in
                delegate.contacts.sort(by: { $0[keyPath: groupBy.key] < $1[keyPath: groupBy.key] })
            }
    }
    
    
    @ViewBuilder var groupByPicker : some View {
        Picker("Group By", selection:$groupBy) {
            ForEach(Contact.Group.allCases, id:\.self) {group in
                Text(group.title)
            }
        }.fixedSize()
    }
    @ViewBuilder var filterOptions : some View {
        ForEach(Contact.Show.filterOptions, id:\.self) { option in
            Toggle(option.title, isOn: Binding(get: {show.contains(option)}, set: {_ in toggle(option)}))
                .foregroundStyle(option.asStatus?.color() ?? Color.primary)
        }
    }
    @ViewBuilder var displayOptions : some View {
        ForEach(Contact.Show.displayOptions, id:\.self) { option in
            Toggle(option.title, isOn: Binding(get: {show.contains(option)}, set: {_ in toggle(option)}))
        }
    }
    func toggle(_ option:Contact.Show) {
        if show.contains(option) {
            show.removeAll(where: {$0 == option})
        } else {
            show.append(option)
        }
    }
}

#Preview {
    ContactsFilter(style:.form)
        .environment(ContactsDelegate())
}
