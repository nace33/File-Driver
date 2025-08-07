//
//  Case.TrackerInspector.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/5/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct Case_TrackerInspector: View {
    @Environment(TrackerDelegate.self) var delegate
    let threadID : String
  
    @State private var selected : Case.Tracker?
    @State private var editItem : Case.Tracker?
    @AppStorage("FileDriver.Case_TrackerInspector.showHidden") private var showHidden = false
    
 
    fileprivate var filteredTrackers : [Binding<[Case.Tracker]>.Element] {
        Bindable(delegate).aCase.trackers.filter{ tracker in
            tracker.wrappedValue.threadID == threadID
        }
    }
    
    var body: some View {
        VSplitView {
  
            TrackersList(trackers:filteredTrackers, selected: $selected)
                .contextMenu(forSelectionType: Case.Tracker.self, menu: {menu($0)})
                .frame(minHeight:250)
 
            VStack(spacing:0) {
                Divider()
                if let selected, selected.fileIDs.count > 0 {
                    DriveFileView(files(ids:selected.fileIDs), isLoading: true)
                } else {
                    noFileToPreview
                }
            }
                .layoutPriority(1)
                .frame(minHeight:200)
        }
            .sheet(item: $editItem) { EditTracker(tracker: $0)  }
    }
    
    @ViewBuilder func menu(_ trackers:Set<Case.Tracker>) -> some View {
        if trackers.count == 1, let item = trackers.first {
            Button("Edit") { editItem = item }
                .modifierKeyAlternate(.option) {
                    item.id.copyToClipbarButton("Copy Tracker ID to Clipboard")
                }
            
            Divider()
            Text("Created: \(item.date.mmddyyyy)")
            Text("By: \(item.createdBy)")
        }
    }

    func files(ids:[String]) -> [GTLRDrive_File] {
        ids.compactMap { id in
            let file = GTLRDrive_File()
            file.identifier = id
            file.name = delegate.aCase.files.first(where: { $0.id == id})?.name ?? "\(id)"
            return file
        }
    }
    @ViewBuilder var noFileToPreview : some View {
        VStack {
            Spacer()
            if selected != nil {
                Text("No File to Preview.")
                    .foregroundStyle(.secondary)
                Text("🙈").font(.largeTitle)
            } else {
                Text("No Selection").foregroundStyle(.secondary)
            }
            Spacer()
        }.frame(maxHeight: .infinity)
    }
}



fileprivate struct TrackersList: View {
    var trackers : [Binding<[Case.Tracker]>.Element]
    @Binding var selected : Case.Tracker?
    @AppStorage("FileDriver.Case_TrackerInspector.showHidden") private var showHidden = false
    @Environment(TrackerDelegate.self) var delegate
    @State private var showAppendTrackerSheet = false
    @State private var showFileUploadSheet    = false
    
    var body: some View {
        List(selection: $selected) {
            Section {
                if trackers.isEmpty { Text("No Trackers").foregroundStyle(.secondary)}
                ForEach(trackers.filter({ !$0.wrappedValue.isHidden || showHidden}), id:\.wrappedValue.self) { tracker in
                    Case_TrackerRow(tracker: tracker, elements: [.status, .date, .contact, .tag, .text], isSelected: tracker.wrappedValue == selected)
                        .padding(.leading, tracker.wrappedValue.isHidden ? 20 : 0)
                }
                    .listRowSeparator(.hidden, edges:.top)
            } header: {
                HStack {
                    Menu {
                        Button("Upload File")   { showFileUploadSheet    = true }
                        Button("Text Update")   { showAppendTrackerSheet = true }
                    }label: {
                        Text("Tracker History")
                            .font(.subheadline).bold().foregroundStyle(.secondary)
                    }
                        .disabled(delegate.selectedRootID == nil )
                        .fixedSize()
                        .menuStyle(.borderlessButton)
             
                    Spacer()
                    let hiddenItems = trackers.filter({$0.wrappedValue.isHidden})
                    if hiddenItems.count > 0 {
                        Button(showHidden ? "Hide Hidden" : "\(hiddenItems.count) Hidden") { withAnimation { showHidden.toggle() }}
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }.lineLimit(1)
            }
        }
        .sheet(isPresented: $showAppendTrackerSheet) { AppendTracker()     }
        .sheet(isPresented: $showFileUploadSheet   ) { FileUploadTracker(aCase: delegate.aCase) }
    }
}


