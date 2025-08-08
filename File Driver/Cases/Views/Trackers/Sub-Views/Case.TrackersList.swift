
//  Case.TrackersList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/5/25.
//

import SwiftUI
import BOF_SecretSauce

struct Case_TrackersList: View {
    @Environment(TrackerDelegate.self) var delegate
    @AppStorage("FileDriver.Case_TrackersList.sortTableBy") private var sortBy : TrackerDelegate.SortBy = .date
    @AppStorage("FileDriver.Case_TrackersList.groupBy") private var groupBy = TrackerDelegate.GroupBy.none

    var body: some View {
        List(selection: Bindable(delegate).selectedRootID) {
            switch groupBy {
            case .none:
                noGroupView
            case .category:
                categoryGroupView
            case .status:
                statusGroupView
            case .date:
                dateGroupView
            case .createdBy:
                createdByGroupView
            }
        }
            .alternatingRowBackgrounds()
            .task(id:delegate.trackerRoots) { sort() }
            .onChange(of: sortBy, { _, _ in sort()})
    }
}


//MARK: Sort
extension Case_TrackersList {
    func sort() {
        let keyPathComparator : KeyPathComparator<TrackerRoot>
        keyPathComparator = switch self.sortBy {
        case .date:
            KeyPathComparator(\.date, order: .reverse)
        case .contacts:
            KeyPathComparator(\.contacts.count, order: .reverse)
        case .tags:
            KeyPathComparator(\.tags.count, order: .reverse)
        case .status:
            KeyPathComparator(\.status.intValue, order: .forward)
        case .category:
            KeyPathComparator(\.catString, order: .forward)
        case .createdBy:
            KeyPathComparator(\.createdBy, order: .forward)
        case .text:
            KeyPathComparator(\.text, order: .forward)
        }
        delegate.trackerRoots.sort(using: keyPathComparator)
    }
}


//MARK: View Builders
extension Case_TrackersList {
    @ViewBuilder var noGroupView        : some View {
        ForEach(delegate.filteredRoots, id:\.id) { root in
            Case_TrackersSummaryRow(root: root, groupedBy: groupBy)
        }
    }
    @ViewBuilder var categoryGroupView  : some View {
        let filteredRoots = delegate.filteredRoots
        let catStrings = filteredRoots.map(\.wrappedValue.catString).unique().sorted()
        ForEach(catStrings, id:\.self) { catString in
            let matches = filteredRoots.filter({$0.wrappedValue.catString == catString})
            if matches.count > 0 {
                Section(catString.camelCaseToWords) {
                    ForEach(matches) { root in
                        Case_TrackersSummaryRow(root: root, groupedBy: groupBy)
                    }
                }
            }
        }.listRowSeparator(.hidden, edges: .top)
    }
    @ViewBuilder var statusGroupView    : some View {
        let filteredRoots = delegate.filteredRoots
        let allStatus = filteredRoots.map(\.wrappedValue.status).unique().sorted(by: {$0.intValue < $1.intValue})
        ForEach(allStatus, id:\.self) { status in
            let matches = filteredRoots.filter({$0.wrappedValue.status == status})
            if matches.count > 0 {
                Section(status.rawValue.camelCaseToWords) {
                    ForEach(matches) { root in
                        Case_TrackersSummaryRow(root: root, groupedBy: groupBy)
                    }
                }
            }
        }.listRowSeparator(.hidden, edges: .top)

    }
    @ViewBuilder var dateGroupView      : some View {
        Date.Section.listSection(items: delegate.filteredRoots, dateKey:\.date) { root in
            Case_TrackersSummaryRow(root: root, groupedBy: groupBy)
        }
    }
    @ViewBuilder var createdByGroupView : some View {
        let filteredRoots = delegate.filteredRoots
        let allCreators = filteredRoots.map(\.wrappedValue.createdBy).unique().sorted()
        ForEach(allCreators, id:\.self) { creator in
            let matches = filteredRoots.filter({$0.wrappedValue.createdBy == creator})
            if matches.count > 0 {
                Section(creator) {
                    ForEach(matches) { root in
                        Case_TrackersSummaryRow(root: root, groupedBy: groupBy)
                    }
                }
            }
        }.listRowSeparator(.hidden, edges: .top)
    }
}

