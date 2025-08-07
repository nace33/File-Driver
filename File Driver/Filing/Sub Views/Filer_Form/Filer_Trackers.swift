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
                    .popover(isPresented: $showTrackersList, arrowEdge:.bottom) {
                        SelectTracker() {
                            state = .updateRoot($0)
                        }
                            .environment(trackerDelegate)
                    }
            }
            ForEach(Bindable(delegate).trackers) { tracker in
                Filer_Tracker(tracker:tracker, isNewTracker: isNewTracker)
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
       
//            if roots.count > 0 {
//                Divider()
//                statusMenu(roots)
//                categoryMenu(roots)
//                contactsMenu(roots)
//                tagsMenu(roots)
//                datesMenu(roots)
//                Divider()
//                Button("Show Trackers List") { showTrackersList = true }
//            } else {
//                ForEach(roots) { root in
//                    Button(root.menuTitle(maxLength:100)) { state = .updateRoot(root) }
//                }
//            }
        }
    }
    /*
    @ViewBuilder func statusMenu(_ roots:[TrackerRoot]) -> some View {
        if roots.count > 0 {
            Menu("Status") {
                ForEach(Case.Tracker.Status.allCases, id:\.self) { status in
                    let statRoots = roots.filter { $0.status == status }
                    if statRoots.count > 0 {
                        Menu(status.title) {
                            ForEach(statRoots) { root in
                                Button(root.menuTitle(maxLength:100)) { state = .updateRoot(root) }
                            }
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder func categoryMenu(_ roots:[TrackerRoot]) -> some View {
        if roots.count > 0 {
            Menu("Category") {
                let allCategories = roots.map(\.catString).unique().sorted()
                ForEach(allCategories, id:\.self) { catString in
                    let catRoots = roots.filter { $0.catString == catString }
                    if catRoots.count > 0 {
                        Menu(catString.capitalized) {
                            ForEach(catRoots) { root in
                                Button(root.string(elements: [.date, .contact, .tag, .text], maxLength: 100)) { state = .updateRoot(root) }
                            }
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder func contactsMenu(_ roots:[TrackerRoot]) -> some View {
        if roots.count > 0 {
            let allContacts = Set(roots.map(\.contacts).flatMap({$0})).sorted(by: {$0.name < $1.name})
            if allContacts.count > 0 {
                Menu("Contacts") {
                    ForEach(allContacts) { contact in
                        let contactRoots = roots.filter { $0.contacts.map(\.id).contains(contact.id)   }
                        if contactRoots.count > 0 {
                            Menu(contact.name) {
                                ForEach(contactRoots) { root in
                                    Button(root.menuTitle(maxLength:100)) { state = .updateRoot(root) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder func tagsMenu(_ roots:[TrackerRoot]) -> some View {
        if roots.count > 0 {
            let allTags = Set(roots.map(\.tags).flatMap({$0})).sorted(by: {$0.name < $1.name})
            if allTags.count > 0 {
                Menu("Tags") {
                    ForEach(allTags) { tag in
                        let tagRoots = roots.filter { $0.tags.map(\.id).contains(tag.id)   }
                        if tagRoots.count > 0 {
                            Menu(tag.name) {
                                ForEach(tagRoots) { root in
                                    Button(root.menuTitle(maxLength:100)) { state = .updateRoot(root) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder func datesMenu(_ roots:[TrackerRoot]) -> some View {
        if roots.count > 0 {
            Menu("Dates") {
                ForEach(Date.Section.allCases, id:\.self) { dateSection in
                    let sectionItems = dateSection.dates(for:roots, with:\.date)
                    if sectionItems.count > 0  {
                        Menu(dateSection.rawValue.camelCaseToWords) {
                            ForEach(sectionItems) { root in
                                Button(root.menuTitle(maxLength:100)) { state = .updateRoot(root) }
                                
                            }
                        }
                    }
                }
            }
        }
    }
    */
}

//MARK: - Form
struct Filer_Tracker : View {
    @Environment(Filer_Delegate.self) var delegate
    @Binding var tracker : Case.Tracker
    let isNewTracker : Bool
    /*
        UI Needs to know whethere this is an update or new request
    */
    @FocusState private var isFocused
    
    var body: some View {
        if isNewTracker {
            categoryPicker
        }
   
        statusPicker

        if tracker.category == .custom {
            TextField("", text: $tracker.catString, prompt: Text("Enter custom category here"))
                .focused($isFocused)
        }
        
        TextField("Comment", text:$tracker.text, prompt: Text("Enter comment here"), axis:.vertical)

        if isNewTracker, delegate.items.count > 1 {
            Toggle("Apply tracker to each file", isOn: Bindable(delegate).oneTrackerPerFile)
        }
    }
    
    @ViewBuilder var categoryPicker  : some View {
        Picker("Category", selection: $tracker.category) {
            let allCatogories = Case.Tracker.Category.allCases
            ForEach(allCatogories, id:\.self) { t in
                if t == allCatogories.last {
                    Divider()
                }
                Text(t.title)
            }
        } currentValueLabel: {
            let cat = Case.Tracker.Category(rawValue:tracker.catString.lowercased()) ?? .custom
            Text(cat.title)
        }
        .onChange(of: tracker.category) { oldValue, newValue in
            if newValue == .custom && tracker.catString == "custom" {
                tracker.catString = ""
                isFocused = true
            }
        }
    }
    
    @ViewBuilder var statusPicker    : some View {
        Picker("Status", selection: $tracker.status) {
            ForEach(Case.Tracker.Status.allCases, id:\.self) { t in
                Text(t.title)
            }
        }
    }
}

