//
//  Cases_Table.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//

import SwiftUI

struct Cases_Table: View {
    @AppStorage(BOF_Settings.Key.casesFilingTableColumnKey.rawValue)     var columnKey  : TableColumnCustomization<Case>
    @State private var sortOrder = [KeyPathComparator(\Case.title)]
    @State private var cases: [Case] = []
    @State private var selectedID : Case.ID?
    @AppStorage(BOF_Settings.Key.caseFilingShowStatusColorsKey.rawValue)  var showStatusColors : Bool = true

    var filteredCases: [Case] {
        cases
    }
    var body: some View {
        tableView
            .onChange(of: sortOrder) { _, newOrder in
                cases.sort(using: newOrder)
            }
    }
    

    @ViewBuilder var tableView : some View {
        HStack {
            Spacer()
            sortKeyPathView()
        }.padding([.top, .trailing], 8)
        Table(filteredCases, selection: $selectedID, sortOrder: $sortOrder, columnCustomization: $columnKey) {
            TableColumn("Title", value: \.title) { aCase in
                Text(aCase.title)
            }
                .customizationID("Title")
            TableColumn("Type", value: \.driveLabel.category.title) { aCase in
                Text(aCase.driveLabel.category.title)
            }
                .customizationID("Type")
            TableColumn("Status", value: \.driveLabel.status.intValue) { aCase in
                Text(aCase.driveLabel.status.title)
                    .foregroundStyle(showStatusColors ? aCase.driveLabel.status.color : .primary)
            }
                .customizationID("Status")
            TableColumn("Opened", value: \.driveLabel.opened) { aCase in
                Text(aCase.driveLabel.opened.mmddyyyy)
            }
                .customizationID("Opened")
            TableColumn("Closed") { aCase in
                Text(aCase.driveLabel.closed?.mmddyyyy ?? "")
            }
                .customizationID("Closed")
        }
  
    }
}

extension Cases_Table {
    func tableSortKeyPaths() -> [String] {
        sortOrder
            .map {
                let keyPath = $0.keyPath
                let sortOrder = $0.order
                var keyPathString = ""
                switch keyPath {
                case \Case.title:
                    keyPathString = "Title"
                case \Case.driveLabel.category.title:
                    keyPathString = "Category"
                case \Case.driveLabel.status.intValue:
                    keyPathString = "Status"
                case \Case.driveLabel.opened:
                    keyPathString = "Opened"
                case \Case.driveLabel.closed:
                    keyPathString = "Closed"
                default:
                    break
                }

                return keyPathString + (sortOrder == .reverse ? "↓" : "↑")
            }
    }
    @ViewBuilder func sortKeyPathView() -> some View {
         HStack {
             ForEach(tableSortKeyPaths(), id: \.self) { sortKeyPath in
                 Text(sortKeyPath)
             }
         }
     }
}
