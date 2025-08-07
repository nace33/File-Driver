//
//  TrackerRoot.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/4/25.
//

import Foundation

/*
extension Case {
    
    struct TrackerRoot : Identifiable, Hashable {
        let id : String
        let threadID : String
        private(set) var trackers    : [Case.Tracker]
        private(set) var isDisclosed : Bool = false
        private(set) var catString   : String
        
        
        private(set) var contactIDs  : Set<String>
        var contacts    : Set<Case.Contact>
        private(set) var tagIDs      : Set<String>
        var tags        : Set<Case.Tag>
        private(set) var fileIDs     : Set<String>
        private(set) var createdBys  : Set<String>
        
        init?(trackers:[Case.Tracker]) {
            guard trackers.count > 0 else { return nil }
            self.id         = UUID().uuidString
            self.trackers   = trackers.sorted(by: {$0.date < $1.date})
            self.threadID   = trackers.first?.threadID ?? ""

            self.catString  = trackers.first!.catString
            
            self.contactIDs = Set(trackers.map(\.contactIDs).flatMap({$0}))
            self.tagIDs     = Set(trackers.map(\.tagIDs).flatMap({$0}))
            self.fileIDs    = Set(trackers.map(\.fileIDs).flatMap({$0}))
            self.createdBys = Set(trackers.map(\.createdBy))

            //loaded later in UI calls
            self.tags = []
            self.contacts = []
        }
        
        //Computed Properties
        var firstDate   : Date  { trackers.first!.date }
        var lastDate    : Date  { trackers.last!.date  }
        var text        : String {
            for tracker in trackers.reversed()  {
                if tracker.text.isEmpty { continue }
                else {
                    return tracker.text
                }
            }
            return ""
        }
        var status      : Case.Tracker.Status {
            trackers.last?.status ?? .paused
        }
        mutating func update(_ tracker:Case.Tracker, contacts: [Case.Contact], tags:[Case.Tag]) {
            if let index = trackers.firstIndex(where: {$0.id == tracker.id}) {
                trackers[index].update(with: tracker)
                updateRootRowItems(contacts: contacts, tags: tags)
            }
        }
        mutating func remove(_ tracker:Case.Tracker) {
            if let index = trackers.firstIndex(where: {$0.id == tracker.id}) {
                trackers.remove(at: index)
            }
        }
        mutating func add(_ tracker:Case.Tracker, contacts:Set<Case.Contact>, tags:Set<Case.Tag>) {
            trackers.append(tracker)
            contactIDs.formUnion(tracker.contactIDs)
            tagIDs.formUnion(tracker.tagIDs)
            fileIDs.formUnion(tracker.fileIDs)
            createdBys.insert(tracker.createdBy)
            self.contacts.formUnion(contacts)
            self.tags.formUnion(tags)
            self.rowItems = createRowItems(contacts: contacts, tags: tags)
        }
    
        //var tagsCount : Int { tagIDs.count }
        var searchString : String {
            var texts = [String]()
            texts += trackers.map(\.text)
            texts += trackers.map(\.date.mmddyyyy)
            texts += createdBys
            return texts.joined(separator: " ")
        }
        var createdBy : String { trackers.first?.createdBy ?? ""}
        
        
        var rowItems  : [RowItem] = []
        func createRowItems(contacts: Set<Case.Contact>, tags:Set<Case.Tag>) -> [RowItem] {
            var tempItems = [Case.TrackerRoot.RowItem]()
       
            tempItems.append(.init(text: "", style: .circle(status.color)))
            tempItems.append(.init(text: lastDate.mmddyyyy, style: .date))
            
            tempItems.append(.init(text: catString.capitalized, style: .category))
            
            
            tempItems.append(contentsOf: contacts.compactMap({ contact in
                .init(text: contact.name, style: .token(.blue))
            }))
            tempItems.append(contentsOf: tags.compactMap({ tag in
                .init(text: tag.name, style: .token(.green))
            }))
            
            let text = self.text
            if !text.isEmpty {
                tempItems.append(.init(text:text, style: .text))
            }
            return tempItems
        }
        mutating func updateRootRowItems(contacts:[Case.Contact], tags:[Case.Tag]) {
            let contactsInRoot = Set(contacts.filter { contactIDs.contains($0.id)})
            let tagsInRoot     = Set(tags.filter     { tagIDs.contains($0.id)})
            self.contacts = contactsInRoot
            self.tags     = tagsInRoot
            updateRowItems(contacts:contactsInRoot, tags:tagsInRoot)
        }
        mutating func updateRowItems(contacts: Set<Case.Contact>, tags:Set<Case.Tag>) {
            rowItems = createRowItems(contacts: contacts, tags: tags)
        }
    }
}
*/
