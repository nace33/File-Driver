//
//  TrackerRoot.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/5/25.
//

import SwiftUI
struct TrackerRoot : Identifiable, Hashable{
    let id       : String
    let threadID : String
    init(_ threadID:String, aCase:Case) {
        self.id       = UUID().uuidString
        self.threadID = threadID
        self.date = Date()
        self.status = .paused
        self.catString = ""
        self.contacts = []
        self.tags    = []
        self.createdBys = []
        self.text    = ""
        self.searchString = ""
        
        rebuild(from: aCase)
    }
    private(set) var date        : Date
    private(set) var status      : Case.Tracker.Status
    private(set) var catString   : String
    private(set) var contacts    : [Case.Contact]
    private(set) var tags        : [Case.Tag]
    private(set) var createdBys  : [String]
    private(set) var text        : String
    private(set) var searchString: String
    
    var isEmpty     : Bool = false
    var showHidden  : Bool = false
    var createdBy   : String { createdBys.last ?? "" }
    var categoryTitle : String {
        let cat = Case.Tracker.Category(string:catString)
        return switch cat {
        case .custom:
            catString
        default:
            cat.title
        }
    }
    func menuTitle(maxLength:Int? = nil) -> String {
        string(elements: [.date, .category, .contact, .tag, .text], maxLength: maxLength)
    }
    var contactIDs : Set<String> { Set(contacts.map(\.id))}
    var tagIDs : Set<String> { Set(tags.map(\.id))}
    var contactAndTagIDs : Set<String> { contactIDs.union(tagIDs)}
    mutating func rebuild(from aCase:Case) {
        let trackers = aCase.trackers.filter({$0.threadID == threadID && (showHidden || !$0.isHidden)})
                                     .sorted(by: {$0.date < $1.date})
    
        if let mostRecentTracker = trackers.last {
            isEmpty = false
            date        = mostRecentTracker.date
            status      = mostRecentTracker.status
            catString   = mostRecentTracker.catString
            
            var contactIDs : [Case.Contact.ID] = []
            var tagIDs     : [Case.Contact.ID] = []
            var creators   : [String] = []
            for tracker in trackers {
                for contactID in tracker.contactIDs {
                    if !contactIDs.contains(contactID) {
                        contactIDs.append(contactID)
                    }
                }
                for tagID in tracker.tagIDs {
                    if !tagIDs.contains(tagID) {
                        tagIDs.append(tagID)
                    }
                }
                if !creators.contains(tracker.createdBy) {
                    creators.append(tracker.createdBy)
                }
            }
            contacts    = aCase.contacts(with: contactIDs)
            tags        = aCase.tags(with: tagIDs)
            createdBys  = creators
            
            for tracker in trackers.reversed() {
                if !tracker.text.isEmpty {
                    text = tracker.text
                    break
                }
            }
            
            searchString = ( trackers.map(\.text) + trackers.map(\.date.mmddyyyy) + createdBys + contacts.map(\.name) + tags.map(\.name) + [status.rawValue] + [catString]).joined(separator: " ")
        } else {
            isEmpty = true
        }
    }
}
