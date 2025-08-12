//
//  Case.TrackerDelegate.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/5/25.
//

import SwiftUI

@Observable

final class TrackerDelegate {
    var aCase : Case
    
    init(_ aCase: Case) {
        self.aCase = aCase
    }
    var trackerRoots: [TrackerRoot] = []
    var loader = VLoader_Item(isLoading:false)
    var filter = Filter()
    var selectedRootID : TrackerRoot.ID? = nil
    
    var hideStoppedTrackers : Bool {
        get { UserDefaults.standard.bool(forKey: "Filer-Driver.TrackerDelegate.hideStoppedTrackers")}
        set {
            UserDefaults.standard.setValue(newValue, forKey: "Filer-Driver.TrackerDelegate.hideStoppedTrackers")
            loadFilterTokens()
        }
    }
    var oneLineLimit : Bool {
        get { UserDefaults.standard.bool(forKey: "Filer-Driver.TrackerDelegate.oneLineLimit")}
        set { UserDefaults.standard.setValue(newValue, forKey: "Filer-Driver.TrackerDelegate.oneLineLimit") }
    }
}

//MARK: - Enums
extension TrackerDelegate {
    enum GroupBy: String, CaseIterable, Codable { case none, status, category, date, createdBy  }
    enum SortBy : String, CaseIterable, Codable { case date, contacts, tags, status, category, createdBy, text  }
}


//MARK: - Local Model Update
extension TrackerDelegate {
    func loadTrackerRoots() {
        let threads = aCase.trackers.map(\.threadID).unique()
        
        trackerRoots = threads.compactMap { TrackerRoot($0, aCase: aCase) }
            
        loadFilterTokens()
    }
    func rebuild(threadID:String) {
        if let root = Bindable(self).trackerRoots.first(where: {$0.wrappedValue.threadID == threadID}) {
            root.wrappedValue.rebuild(from: aCase)
        } else {
            trackerRoots.append(TrackerRoot(threadID, aCase: aCase))
        }
        loadFilterTokens()
    }
}


//MARK: - Filter
extension TrackerDelegate {
    var selectedRoot : Binding<TrackerRoot>? { filteredRoots.first(where: {$0.wrappedValue.id == selectedRootID})}
    var filteredRoots : [Binding<[TrackerRoot]>.Element] {
        Bindable(self).trackerRoots.filter { root in
            if hideStoppedTrackers && root.wrappedValue.status == .stopped { return false }
            if !filter.string.isEmpty, !filter.hasTokenPrefix, !root.wrappedValue.searchString.ciContain(filter.string) { return false   }
            if !filter.tokens.isEmpty {
                for token in filter.tokens {
                    if token.prefix == .atSign {
                        if root.wrappedValue.status.rawValue != token.rawValue { return false }
                    }
                    if token.prefix == .hashTag {
                        if root.wrappedValue.catString   != token.rawValue { return false }
                    }
                    else if token.prefix == .dollarSign {
                        if !root.wrappedValue.contacts.map(\.id).contains(token.rawValue) && !root.wrappedValue.tags.map(\.id).contains(token.rawValue) { return false }
                    }
                }
            }
            return true
        }
    }
    func loadFilterTokens() {
        //At signs
        let rootsToUse    = hideStoppedTrackers ? trackerRoots.filter({ $0.status != .stopped}) : trackerRoots
        
       
        let atSigns       = rootsToUse.map(\.status.rawValue).unique().sorted(by: <).compactMap { Filter.Token(prefix: .atSign, title: $0.capitalized, rawValue: $0)  }

        //Hash Tags
        let hashTags      = rootsToUse.map(\.catString).unique().sorted(by: <).compactMap { Filter.Token(prefix: .hashTag, title: $0.capitalized, rawValue: $0)  }

        var dollarSigns   : [Filter.Token] = []
        let contactsToUse = Set(rootsToUse.map(\.contactIDs).flatMap({$0}))
        let tagsToUse     = Set(rootsToUse.map(\.tagIDs).flatMap({$0}))
        dollarSigns.append(contentsOf: aCase.contacts.filter({contactsToUse.contains($0.id)}).compactMap({Filter.Token(prefix: .dollarSign, title: $0.name, rawValue: $0.id)}))
        dollarSigns.append(contentsOf: aCase.tags.filter({tagsToUse.contains($0.id)}).compactMap({Filter.Token(prefix: .dollarSign, title: $0.name, rawValue: $0.id)}))

        filter.allTokens = atSigns + hashTags + dollarSigns
    }
}


//MARK: - Sheets Calls
extension TrackerDelegate {
    func newRoot(_ tracker:Case.Tracker, contacts:[Case.Contact], tags:[Case.Tag]) async throws {
        do {
            loader.start()
            
            //Update Spreadsheet
            let newContacts = contacts.filter { !aCase.isInSpreadsheet($0.id, sheet: .contacts)}
            let newTags     = tags.filter { !aCase.isInSpreadsheet($0.id, sheet: .tags)}
            let appendRows : [any GoogleSheetRow] = newContacts + newTags + [tracker]
            try await Sheets.shared.append(appendRows, to: aCase.id)
            
            //Update Case
            aCase.contacts.append(contentsOf: newContacts)
            aCase.tags.append(contentsOf: newTags)
            aCase.trackers.append(tracker)
            
            //Update Tracking Root
            rebuild(threadID: tracker.threadID)
            
            loader.stop()
            loadFilterTokens()
        } catch {
            loader.stop(error)
            throw error
        }
    }
    func append(_ tracker:Case.Tracker, in root:TrackerRoot, contacts:[Case.Contact], tags:[Case.Tag]) async throws {
        do {
            loader.start()
            
            //Update Spreadsheet
            let newContacts = contacts.filter { !aCase.isInSpreadsheet($0.id, sheet: .contacts)}
            let newTags     = tags.filter { !aCase.isInSpreadsheet($0.id, sheet: .tags)}
            let appendRows : [any GoogleSheetRow] = newContacts + newTags + [tracker]
            try await Sheets.shared.append(appendRows, to: aCase.id)

            //Update Case
            aCase.contacts.append(contentsOf: newContacts)
            aCase.tags.append(contentsOf: newTags)
            aCase.trackers.append(tracker)
            
            //Update Tracking Root
            rebuild(threadID: tracker.threadID)
            
            loader.stop()
            loadFilterTokens()
        } catch {
            loader.stop(error)
            throw error
        }
    }
    func edit(_ tracker:Case.Tracker, contacts:[Case.Contact], tags:[Case.Tag]) async throws {
        do {
            loader.start()
            
            guard let existing = aCase.trackers.first(where: {$0.id == tracker.id}) else {throw NSError.quick("Local tracker not found.") }
            
            //Append New Ros to Spreadsheet, if needed
            let newContacts = contacts.filter { !aCase.isInSpreadsheet($0.id, sheet: .contacts)}
            let newTags     = tags.filter { !aCase.isInSpreadsheet($0.id, sheet: .tags)}
            var appendRows : [any GoogleSheetRow] = []
            appendRows += newContacts
            appendRows += newTags
            if appendRows.count > 0 {
                try await Sheets.shared.append(appendRows, to: aCase.id)
            }
            
            //Update tracker and possible thread if category changed
            var updateTrackers : [Case.Tracker] = [tracker]
            let updateEntireThread = existing.catString != tracker.catString
            if updateEntireThread {
                let allTrackers = aCase.trackers.filter { $0.threadID == tracker.threadID && $0.id != tracker.id}
                for needsToUpdateTracker in allTrackers {
                    var edit = Case.Tracker(edit: needsToUpdateTracker)
                    edit.catString = tracker.catString
                    updateTrackers.append(edit)
                }
            }

            try await Sheets.shared.update(spreadsheetID:aCase.id, sheetRows: updateTrackers)

            //Update Case
            aCase.contacts.append(contentsOf: newContacts)
            aCase.tags.append(contentsOf: newTags)
            for updateTracker in updateTrackers {
                if let existingTracker = Bindable(aCase).trackers.first(where: {$0.id == updateTracker.id}) {
                    existingTracker.wrappedValue.update(with:updateTracker)
                }
            }
            
            //Update Tracking Root
            rebuild(threadID: tracker.threadID)
          
            
            loader.stop()
            loadFilterTokens()
        } catch {
            loader.stop(error)
            throw error
        }
    }
    func updateStatus(root:TrackerRoot, status:Case.Tracker.Status) {
        guard root.status != status else { return }
        var newTracker = Case.Tracker(root: root)
        newTracker.status = status
        
        Task {
            try? await append(newTracker, in: root, contacts: [], tags: [])
        }
    }
}
