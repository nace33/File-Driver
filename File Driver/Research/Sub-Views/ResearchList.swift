//
//  ResearchList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/12/25.
//

import SwiftUI


struct ResearchList: View {
    let showFilter :Bool
    @Environment(ResearchDelegate.self) var delegate
    @AppStorage(BOF_Settings.Key.researchGroupBy.rawValue)  var groupBy     : Research.Group = .category
    @AppStorage(BOF_Settings.Key.researchShow.rawValue)    var show     : [Research.Show] = Research.Show.allCases
    
    var body: some View {
        VStack(spacing:0) {
            let filteredItems = delegate.filteredItems
            ScrollViewReader { proxy in
                List(selection: Bindable(delegate).selectedIDs) {
                    if filteredItems.isEmpty {  noFilteredItemsView }
                    BOFBoundSections(of: filteredItems, groupedBy: groupBy.key, isAlphabetic: groupBy.isAlphabetic) { header in
                        Text(header.isEmpty ? "No Sub-Category" : header)
                    } row: { research in
                        ResearchRow(research:research)
                    }
                        .listRowSeparator(.hidden)
                }
                    .onChange(of: delegate.scrollToID) { _, newID in  proxy.scrollTo(newID)  }
            }
            
            if showFilter {
                Filter_Footer(count:filteredItems.count, title:"Research") {
                    ResearchFilter()
                }
            }
        }
            //this is triggered when 'show' is changed, and casues view to update
            //checkSelection does not need to be called for the sort to occur, the view itself is beign reloaded
            .onChange(of: show) { oldValue, newValue in delegate.checkSelection()}
    }

    
    @ViewBuilder var noFilteredItemsView : some View {
        if delegate.items.count > 0 {
            VStack(alignment:.leading) {
                Text("No Research Found")
                    .foregroundStyle(.secondary)
                Text("Try changing your filter settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("No Research Found")
                .foregroundStyle(.secondary)
        }
    }
}
