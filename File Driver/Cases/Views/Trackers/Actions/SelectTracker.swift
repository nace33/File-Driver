//
//  SelectTracker.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/7/25.
//

import SwiftUI

struct SelectTracker: View {
    @Environment(TrackerDelegate.self) var delegate
    @Environment(\.dismiss) var dismiss
    let selected : (TrackerRoot) -> Void
    
    var body: some View {
        VStack(alignment:.leading, spacing:0) {
            HStack {
                Text("Select Tracker")
                    .foregroundStyle(.secondary)
                    .font(.title2)
                    .bold()
                Spacer()
                TextField("Search Trackers", text: Bindable(delegate).filter.string, prompt: Text("Filter"))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .frame(width:150)
                    .focusable(false)
                
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider()
            Case_TrackersList()
//                .listStyle(.sidebar)
                .contextMenu(forSelectionType: TrackerRoot.ID.self, menu: {itemIDs in
                    if let itemID = itemIDs.first, let root = delegate.trackerRoots.first(where: {$0.id == itemID}) {
                        Button("Select") {
                            select(root)
                        }
                        Divider()
                    }
                    Case_TrackersFilter()
                }, primaryAction: { itemIDs in
                    if let itemID = itemIDs.first, let root = delegate.trackerRoots.first(where: {$0.id == itemID}) {
                        select(root)
                    }
                })
//                .searchable(text:Bindable(delegate).filter.string,
//                            tokens: Bindable(delegate).filter.tokens,
//                            placement:.automatic,
//                            prompt: Text("Filter")) { Text($0.title) }
//                .searchSuggestions { delegate.filter.searchSuggestions }
        }
            .presentationSizing(.fitted) // Allows resizing, sizes to content initially
            .frame(minWidth:400, minHeight:400)

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Select Tracker") { select(delegate.selectedRoot!.wrappedValue)  }
                        .disabled(delegate.selectedRootID == nil )
                }
            }
    }
    
    func select(_ root:TrackerRoot) {
        dismiss()
        selected(root)
    }
}

