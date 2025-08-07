//
//  Case.TrackersView2.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/4/25.
//

import SwiftUI
import BOF_SecretSauce


struct Case_TrackersView: View {
    @Binding var aCase : Case
    init(_ aCase: Binding<Case>) {
        _aCase = aCase
        _delegate = State(initialValue: TrackerDelegate(aCase.wrappedValue))
    }
    @State private var delegate : TrackerDelegate
    @State private var showNewTrackerSheet    = false
    @State private var showFileUploadSheet    = false
    @AppStorage("FileDriver.CaseTrackerView.showTable") private var showTable = false
    @AppStorage("FileDriver.Case_TrackersList.sortTableBy") private var sortBy : TrackerDelegate.SortBy = .date
    @AppStorage("FileDriver.Case_TrackersList.groupBy") private var groupBy = TrackerDelegate.GroupBy.none

    var body: some View {
        HSplitView {
            VStack(spacing:0) {
                Group {
                    switch showTable {
                    case true:
                        Case_TrackersTable()
                    case false:
                        Case_TrackersList()
                    }
                }
                    .disabled(delegate.loader.isLoading)
                    .contextMenu(forSelectionType: TrackerRoot.ID.self, menu: {  menu($0) })
                Filter_Footer(count:delegate.filteredRoots.count, title: "Trackers") { filterView() }
            }
                .frame(minWidth:300, idealWidth: 400)
              
            inspectorView
                .layoutPriority(1)
                .frame(minWidth:200, maxWidth: .infinity, maxHeight: .infinity)
        }
            .toolbar { toolbarView }
            .sheet(isPresented: $showNewTrackerSheet   ) { NewTracker()        }
            .sheet(isPresented: $showFileUploadSheet   ) { FileUploadTracker(aCase: aCase) }
            .searchable(text:Bindable(delegate).filter.string,tokens: Bindable(delegate).filter.tokens, placement:.toolbar, prompt: Text("Filter")) { Text($0.title) }
            .searchSuggestions { delegate.filter.searchSuggestions }
            .environment(delegate)
            .task(id:aCase.id) { delegate.loadTrackerRoots()}
    }
}



//MARK: - View Builders
extension Case_TrackersView {
    @ToolbarContentBuilder var toolbarView : some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Menu("New") {
                Button("Tracker")     { showNewTrackerSheet = true }
                Button("File Upload") { delegate.selectedRootID = nil; showFileUploadSheet = true }
            }
        }
    }
    @ViewBuilder func menu(_ itemIDs:Set<TrackerRoot.ID>) -> some View {
        if itemIDs.count == 1, let itemID = itemIDs.first, let item = delegate.trackerRoots.first(where: {$0.id == itemID }) {
            Menu("Change Status") {
                ForEach(Case.Tracker.Status.allCases, id:\.self) { status in
                    Button(status.title) { delegate.updateStatus(root:item, status:status)}
                        .disabled(status == item.status)
                }
            }
            .modifierKeyAlternate(.option) {
                item.threadID.copyToClipbarButton("Copy Thread ID to Clipboard")
            }
        }
        else { filterView(isMenu: true) }
   
    }
    @ViewBuilder func filterView(isMenu:Bool = false) -> some View {
        if isMenu {
            Menu("New") {
                Button("Tracker")     { showNewTrackerSheet = true }
                Button("File Upload") { delegate.selectedRootID = nil; showFileUploadSheet = true }
            }
            Divider()
        }
        Case_TrackersFilter()
    }
    @ViewBuilder var inspectorView: some View {
        Group {
            if let selectedRoot = delegate.trackerRoots.first(where: {$0.id == delegate.selectedRootID}) {
                Case_TrackerInspector(threadID: selectedRoot.threadID)
            } else {
                Text("No Selection").foregroundStyle(.secondary)
            }
        }
    }
}



