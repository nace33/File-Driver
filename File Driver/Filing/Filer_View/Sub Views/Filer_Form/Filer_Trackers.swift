//
//  Filer_Trackers2.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/7/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

struct Filer_Trackers: View {
    @Environment(Filer_Delegate.self) var delegate
    @State private var trackerDelegate : TrackerDelegate = .init(Case(file: GTLRDrive_File(), label: .init(folderID: "")))
    @State private var isNewTracker = false
    @State private var state : TrackingState = .none
    @State private var showTrackersList = false
    
    var body: some View {
        Section {
            LabeledContent("Tracking") {
                Menu(state.title) {
                    Button(TrackingState.none.title) { state = .none }
                    Button(TrackingState.new.title)  { state = .new }
                    Divider()
                    Button("Update Existing Tracker") { showTrackersList = true }
                    suggestedTrackersMenu
                }
                .fixedSize()
                .sheet(isPresented: $showTrackersList) {
                    SelectTracker() {
                        state = .updateRoot($0)
                        return true
                    }
                    .environment(trackerDelegate)
                }
            }
            ForEach(Bindable(delegate).trackers) { tracker in
                Filer_NewTracker(tracker:tracker, isNewTracker: isNewTracker)
            }
        }
        .onChange(of: state) { oldValue, newValue in
            switch state {
            case .none:
                removeTrackers()
            case .new:
                newTracker()
            case .updateRoot(let root):
                appendTracker(to:root)
            case .externalUpdate(let tracker):
                externalTrackerAdded(tracker)
            }
        }
        .onChange(of: delegate.trackers) { oldValue, newValue in
            if let tracker = delegate.trackers.first, state == .none {
                state = .externalUpdate(tracker)
            }
        }
        
        .task(id:delegate.selectedCase) {
            if let aCase = delegate.selectedCase {
                trackerDelegate = .init(aCase)
                trackerDelegate.loadTrackerRoots()
            }
        }
    }
    
    //MARK: Functions
    enum TrackingState : Equatable & Hashable {
        case none, new, updateRoot(TrackerRoot), externalUpdate(Case.Tracker)
        var title : String {
            switch self {
            case .none:
                "Off"
            case .new:
                "New Tracker"
            case .updateRoot(let root):
                "Update: \(root.menuTitle(maxLength:40))"
            case .externalUpdate(let tracker):
                "Update: \(tracker.date.mmddyyyy + "  " + tracker.categoryTitle + "  " + tracker.text)"
            }
        }
    }
    func newTracker() {
        isNewTracker = true
        withAnimation {
            delegate.trackers = [Case.Tracker()]
        }
    }
    func externalTrackerAdded(_ tracker:Case.Tracker) {
        isNewTracker = false
        //can already contain tracker if loaded into FilerDelegate in order to pre-set User Interface
        if !delegate.trackers.contains(tracker) {
            //Do not animate, since user did not select through UI
            delegate.trackers = [tracker]
        }
    }
    func appendTracker(to root:TrackerRoot) {
        var tracker = Case.Tracker()
        tracker.threadID = root.threadID
        tracker.catString = root.catString
        isNewTracker = false
        withAnimation {
            delegate.trackers = [tracker]
        }
    }
    func removeTrackers() {
        isNewTracker = false
        withAnimation {
            delegate.trackers.removeAll()
        }
    }
    
    
    //MARK: View Builders
    @ViewBuilder var suggestedTrackersMenu : some View {
        let roots = trackerDelegate.trackerRoots.filter { $0.status != .stopped }
        if roots.count > 0 {
            Divider()
            
            //Display Suggestions
            let existingIDs = Set(delegate.contacts.map(\.id)).union(delegate.tags.map(\.id))
            let existingFilenames = delegate.items.map(\.filename).joined(separator: " ").removeYYYYMMDD.lowerCasedWordsSet
            //suggestions are based on contactIDs and name search.  Preference to contactIDs in the sorting
            //this is possibly very expensive
            let suggestions = roots.filter { $0.contactAndTagIDs.intersection(existingIDs).count > 0 || $0.searchString.lowerCasedWordsSet.intersection(existingFilenames).count > 0 }
                .sorted(by: { lhs, rhs in
                    let lhsCount = lhs.contactAndTagIDs.intersection(existingIDs).count
                    let rhsCount = rhs.contactAndTagIDs.intersection(existingIDs).count
                    if lhsCount == rhsCount {
                        let lhsWordCount = lhs.searchString.lowerCasedWordsSet.intersection(existingFilenames).count
                        let rhsWordCount = rhs.searchString.lowerCasedWordsSet.intersection(existingFilenames).count
                        if lhsWordCount == rhsWordCount {
                            return lhs.date > rhs.date
                        }
                        return lhsWordCount > rhsWordCount
                    } else {
                        return lhsCount > rhsCount
                    }
                })
            if suggestions.count > 0 {
                Section("Suggestions") {
                    ForEach(suggestions.first(5)) { root in
                        Button(root.menuTitle(maxLength:100)) { state = .updateRoot(root) }
                    }
                }
            }
        }
    }
}

//MARK: - Form
fileprivate struct Filer_NewTracker : View {
    @Environment(Filer_Delegate.self) var delegate
    @Binding var tracker : Case.Tracker
    let isNewTracker : Bool //UI Needs to know whethere this is an update or new request
    
    var body: some View {
        
        if isNewTracker {
            FormCustomEnumPicker("Category", selection: $tracker.catString, options: Case.Tracker.Category.allCases, customOption: .custom, titleKey: \.title)
        }
   
        Picker("Status", selection: $tracker.status) { ForEach(Case.Tracker.Status.allCases, id:\.self) { Text($0.title)}}
        
        TextField("Comment", text: $tracker.text, prompt: Text("Enter comment here"))

        if isNewTracker, delegate.items.count > 1 {
            Toggle("Apply tracker to each file", isOn: Bindable(delegate).oneTrackerPerFile)
        }
    }
}

