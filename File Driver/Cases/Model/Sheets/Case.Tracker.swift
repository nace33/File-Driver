//
//  Case.Request.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/31/25.
//

import SwiftUI


extension Case {
    struct Tracker : Identifiable, Hashable {
        var id             : String    //unique identifier
        var dateIDString   : String
        var threadID       : String    //Tracks chains of requests/responses
        var contactIDs     : [String]
        var tagIDs         : [String]
        var fileIDs        : [String]  //Drive File IDs
        var text           : String
        
        
        var catString     : String    //Holds the Category
        var statusString  : String    //Holds the Result
        var createdBy     : String    //Who created the tracker
        var isHidden      : Bool
        
        
        //Not Persisted
        var date          : Date

        
        //Computed
        var title : String {
            var str = ""
            str += date.mmddyyyy
            str += " "
            
            str += catString.capitalized
            if !text.isEmpty {
                str += " ("
                str += text
                str += ")"
            }
            return str
        }
 
        var category  : Case.Tracker.Category {
            get { Category(string: catString) }
            set { catString = newValue.rawValue }
        }
      
        var status  : Case.Tracker.Status {
            get { Status(string: statusString)}
            set { statusString = newValue.rawValue }
        }
        mutating func update(with newValues : Case.Tracker) {
            if contactIDs != newValues.contactIDs {
                contactIDs = newValues.contactIDs
            }
            if tagIDs != newValues.tagIDs {
                tagIDs = newValues.tagIDs
            }
            if fileIDs != newValues.fileIDs {
                fileIDs = newValues.fileIDs
            }
            if text != newValues.text {
                text = newValues.text
            }
            if catString != newValues.catString {
                catString = newValues.catString
            }
            if statusString != newValues.statusString {
                statusString = newValues.statusString
            }
            if isHidden != newValues.isHidden {
                isHidden = newValues.isHidden
            }
        }
        //Enums
        enum Category : String, CaseIterable {
            case authorization, billing, contract, discovery, motion, evidence, opinion, negotiation, settlement, stipulation, custom
            init(string:String) {
                if string.isEmpty { self = .custom }
                else {
                    self = Category(rawValue: string.lowercased()) ?? .custom
                }
            }
            var title : String { rawValue.capitalized }
            var intValue : Int { Self.allCases.firstIndex(of:.init(string: rawValue))!}
        }
        
        enum Status : String, CaseIterable {
            case action, waiting, paused, stopped
            init(string:String) { self = Status(rawValue: string.lowercased()) ?? .waiting}
            var intValue : Int { Status.allCases.firstIndex(of: self)! }
            var title : String { rawValue.capitalized }
            var color : Color {
                switch self {
                case .action:
                        .blue
                case .waiting:
                        .yellow
                case .paused:
                        .gray
                case .stopped:
                        .red
                }
            }
        }
        var categoryTitle : String {
            let cat = Case.Tracker.Category(string:catString)
            return switch cat {
            case .custom:
                catString
            default:
                cat.title
            }
        }
    }


}

extension Case.Tracker {
    init(createFrom request:Case.Tracker) {
        self = .init(threadID: request.threadID,  category: request.category, status: request.status)
    }
    init(threadID: String? = nil, category:Category = .evidence, status:Status = .waiting) {
        self.id = UUID().uuidString
        self.threadID = threadID ?? UUID().uuidString

        let idDateString = Date.idString
        self.dateIDString = idDateString
        self.date = Date.idDate(idDateString)!

        self.contactIDs = []
        self.tagIDs = []
        self.fileIDs = []
        self.text = ""
        self.catString = category.rawValue
        self.statusString = status.rawValue
        self.createdBy = Google.shared.user?.profile?.email ?? ""
        self.isHidden = false
    }
    init(catString:String, status:Status, contactIDs:[String] = [], tagIDs:[String] = [], fileIDs:[String] = [], text:String = "" ) {
        self.id = UUID().uuidString
        self.threadID =  UUID().uuidString

        let idDateString = Date.idString
        self.dateIDString = idDateString
        self.date = Date.idDate(idDateString)!

        self.contactIDs = contactIDs
        self.tagIDs = tagIDs
        self.fileIDs = fileIDs
        self.text = text
        self.catString = catString
        self.statusString = status.rawValue
        self.createdBy = Google.shared.user?.profile?.email ?? ""
        self.isHidden = false
    }
    init(root:TrackerRoot) {
        self.id = UUID().uuidString
        self.threadID = root.threadID
        let idDateString = Date.idString
        self.dateIDString = idDateString
        self.date = Date.idDate(idDateString)!
        self.contactIDs = []
        self.tagIDs = []
        self.fileIDs = []
        self.text = ""
        self.catString = root.catString
        self.statusString = root.status.rawValue
        self.createdBy = Google.shared.user?.profile?.email ?? ""
        self.isHidden = false
    }
    init(edit:Case.Tracker) {
        self.id = edit.id
        self.threadID = edit.threadID
        self.dateIDString = edit.dateIDString
        self.date = edit.date
        self.contactIDs = edit.contactIDs
        self.tagIDs = edit.tagIDs
        self.fileIDs = edit.fileIDs
        self.text = edit.text
        self.catString = edit.catString
        self.statusString = edit.status.rawValue
        self.createdBy = edit.createdBy
        self.isHidden = edit.isHidden
    }

}

import GoogleAPIClientForREST_Sheets
extension Case.Tracker : SheetRow {
    var sheetID: Int { Case.Sheet.trackers.intValue }
    
    init?(rowData: GTLRSheets_RowData) {
        guard let values = rowData.values else { return nil }
        guard values.count  >= 11 else { return nil }
        guard let id            = values[0].formattedValue else { return nil }
        guard let dateIDString  = values[1].formattedValue else { return nil }
        guard let date          = Date.idDate(dateIDString) else { return nil }
        guard let threadID      = values[2].formattedValue else { return nil }
        let contactIDs          = values[3].formattedValue?.commify ?? []
        let tagIDs              = values[4].formattedValue?.commify ?? []
        let fileIDs             = values[5].formattedValue?.commify ?? []
        let text                = values[6].formattedValue ?? ""
        guard let catString     = values[7].formattedValue else { return nil }
        guard let statusString  = values[8].formattedValue else { return nil }
        let createdBy           = values[9].formattedValue  ?? ""
        let isHiddenString      = values[10].formattedValue ?? ""
        let isHidden            = Bool(string: isHiddenString) ?? false

        //Optionals

        //set values
        self.id             = id
        self.dateIDString   = dateIDString
        self.date           = date
        self.threadID       = threadID
        self.contactIDs     = contactIDs
        self.tagIDs         = tagIDs
        self.fileIDs        = fileIDs
        self.text           = text
        self.catString      = catString
        self.statusString   = statusString
        self.createdBy      = createdBy
        self.isHidden       = isHidden
    }

    var cellData: [GTLRSheets_CellData] {[
        Self.stringData(id),
        Self.stringData(dateIDString),
        Self.stringData(threadID),
        Self.stringData(contactIDs.commify),
        Self.stringData(tagIDs.commify),
        Self.stringData(fileIDs.commify),
        Self.stringData(text),
        Self.stringData(catString),
        Self.stringData(statusString),
        Self.stringData(createdBy),
        Self.stringData(isHidden.string)
    ]}
}


