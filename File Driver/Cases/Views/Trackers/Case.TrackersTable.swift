//
//  SwiftUIView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/5/25.
//

import SwiftUI
import BOF_SecretSauce

struct Case_TrackersTable: View {
    @Environment(TrackerDelegate.self) var delegate
    
    @AppStorage("FileDriver.Case_TrackersTable.sortTableBy")  private var mySortThingies     : [MySortThingy] = [.init(keyPath: \TrackerRoot.date.mmddyyyy, sortOrder:.reverse)]
    @AppStorage("FileDriver.Case_TrackersTable.tableColumns") private var tableCustomColumns :TableColumnCustomization<TrackerRoot> = TableColumnCustomization()
    @AppStorage("FileDriver.Case_TrackersList.groupBy") private var groupBy = TrackerDelegate.GroupBy.none

    var body: some View {
        Table(of: TrackerRoot.self, selection:Bindable(delegate).selectedRootID, sortOrder: sortBinding, columnCustomization: $tableCustomColumns) {
            TableColumn("⏺", value:\.status.intValue) { root in
                Text("\(Image(systemName: "circle.fill"))")
                    .font(.system(size: 11))
                    .foregroundStyle(root.status.color)
            }
                .width(min: 22, max:60)
                .alignment(.center)
                .customizationID("statusColumn")
            
            TableColumn("Status", value:\.status.rawValue.capitalized)
                .customizationID("statusStringColumn")
                .defaultVisibility(.hidden)

            TableColumn("Date",     value: \.date.mmddyyyy)
                .width(75)
                .customizationID("dateColumn")
            
            TableColumn("Category", value: \.catString.capitalized)
                .width(min: 75)
                .customizationID("categoryColumn")
            
            TableColumn("Comment", value: \.text)
                .width(min:50)
                .customizationID("commentColumn")
            
      
            TableColumn("Contacts", value:\.contacts.count) { root in
                Text(root.contacts.map(\.name).joined(separator:", "))
            }
                .width(min: 100)
                .customizationID("contactsColumn")
            
            TableColumn("Contacts", value:\.contacts.count) { root in
                Flex_Stack(data:root.contacts) { contact in
                    Text(contact.name)
                        .font(.system(size: 11))
                        .tokenStyle(color:delegate.selectedRootID == root.id ? .primary : .blue, style:.stroke)
                }
            }
                .width(min: 100)
                .customizationID("contactsTokenColumn")
                .defaultVisibility(.hidden)

            TableColumn("Tags", value:\.tags.count) { root in
                Text(root.tags.map(\.name).joined(separator:", "))
            }
                .width(min: 100)
                .customizationID("tagsColumn")
//            
            TableColumn("Tags", value:\.tags.count) { root in
                Flex_Stack(data:root.tags) { tag in
                    Text(tag.name)
                        .font(.system(size: 11))
                        .tokenStyle(color:delegate.selectedRootID == root.id ? .primary : .green, style:.stroke)
                }
            }
                .width(min: 100)
                .customizationID("tagsTokenColumn")
                .defaultVisibility(.hidden)
//
            TableColumn("User", value: \.createdBy)
                .customizationID("userColumn")
                .defaultVisibility(.hidden)

        } rows: {
            switch groupBy {
            case .none:
            ForEach(delegate.filteredRoots.map(\.wrappedValue))
            case .category:
                let allCategories = delegate.filteredRoots.map(\.wrappedValue.catString).unique().sorted(by:<)
                ForEach(allCategories, id:\.self) { catString in
                    let matches = delegate.filteredRoots.filter { $0.wrappedValue.catString == catString }
                    if matches.count > 0 {
                        Section(catString.capitalized) {
                            ForEach(matches.map(\.wrappedValue))
                        }
                    }
                }
            case .status:
                ForEach(Case.Tracker.Status.allCases, id:\.self) { status in
                    let matches = delegate.filteredRoots.filter{$0.wrappedValue.status == status }
                    if matches.count > 0 {
                        Section(status.title) {
                            ForEach(matches.map(\.wrappedValue))
                        }
                    }
                }
            case .date:
                ForEach(Date.Section.allCases, id:\.self) { dateSection in
                    let matches = dateSection.dates(for:delegate.filteredRoots, with:\.wrappedValue.date)
                    if matches.count > 0 {
                        Section(dateSection.rawValue.camelCaseToWords) {
                            ForEach(matches.map(\.wrappedValue))
                        }
                    }
                }
            case .createdBy:
                let users = delegate.filteredRoots.map(\.wrappedValue.createdBy).unique().sorted()
                ForEach(users, id:\.self) { user in
                    let matches = delegate.filteredRoots.filter{$0.wrappedValue.createdBy == user }
                    if matches.count > 0 {
                        Section(user) {
                            ForEach(matches.map(\.wrappedValue))
                        }
                    }
                }
            }
        }
            .onChange(of: mySortThingies) { _, _ in  sort() }
            .task(id:delegate.trackerRoots) { sort()}
    }
}




//MARK: - Sort
extension Case_TrackersTable {
    fileprivate var sortBinding : Binding<[KeyPathComparator<TrackerRoot>]> {
        Binding(get: {
            mySortThingies.compactMap({$0.asComparator})
        }, set: { newValue , _ in
            mySortThingies = MySortThingy.create(current: newValue)
        })
    }
    fileprivate func sort() {
       delegate.trackerRoots.sort(using: mySortThingies.compactMap({$0.asComparator}))
    }
}
fileprivate struct MySortThingy : Codable, Equatable {
    enum Key : String, Codable, Equatable {
        case status, statusString, date, category, text, contacts, tags, user
    }
    let keyPath  : Key
    let sortOrder: SortOrder
    
    init<T>(keyPath: any PartialKeyPath<T> & Sendable, sortOrder: SortOrder) {
        if keyPath == \TrackerRoot.status.intValue {
            self.keyPath = .status
        } else if keyPath == \TrackerRoot.status.rawValue.capitalized {
            self.keyPath = .statusString
        } else if keyPath == \TrackerRoot.date.mmddyyyy {
            self.keyPath = .date
        }
        else if keyPath == \TrackerRoot.catString.capitalized {
            self.keyPath = .category
        }
        else if keyPath == \TrackerRoot.text {
            self.keyPath = .text
        }
        else if keyPath == \TrackerRoot.contacts.count{
            self.keyPath = .contacts
        }
        else if keyPath == \TrackerRoot.tags.count {
            self.keyPath = .tags
        }
        else if keyPath == \TrackerRoot.createdBy{
            self.keyPath = .user
        }
        else {
            print(#function + "\tUnknown Keypath: \(keyPath)")
            self.keyPath = .status
        }
        self.sortOrder = sortOrder
    }
    var asComparator : KeyPathComparator<TrackerRoot> {
        switch keyPath {
        case .status:
            KeyPathComparator(\.status.intValue, order: sortOrder)
        case .statusString:
            KeyPathComparator(\.status.rawValue.capitalized, order: sortOrder)
        case .date:
            KeyPathComparator(\.date.mmddyyyy, order: sortOrder)
        case .category:
            KeyPathComparator(\.catString.capitalized, order: sortOrder)
        case .text:
            KeyPathComparator(\.text, order: sortOrder)
        case .contacts:
            KeyPathComparator(\.contacts.count, order: sortOrder)
        case .tags:
            KeyPathComparator(\.tags.count, order: sortOrder)
        case .user:
            KeyPathComparator(\.createdBy, order: sortOrder)
        }
    }
    static func create(current:[KeyPathComparator<TrackerRoot>]) -> [MySortThingy] {
        current.compactMap { MySortThingy(keyPath: $0.keyPath, sortOrder: $0.order )}
    }

}
