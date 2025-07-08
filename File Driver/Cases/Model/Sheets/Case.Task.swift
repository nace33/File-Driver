//
//  Case.Task.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/26/25.
//

import Foundation
import GoogleAPIClientForREST_Sheets
import BOF_SecretSauce
import SwiftUI
extension Case {
    struct Task : Identifiable, Hashable {
        var id         : String
        var parentID   : String
        var fileIDs    : [String]
        var contactIDs : [String]
        var tagIDs     : [String]
        var assigned   : [String] //can be assied to any person who has share access to the CaseSheet
        var priority   : Priority
        var status     : Status
        var isFlagged  : Bool
        var text       : String
        var dueDate    : Date?
        var note       : String?
  
    
        enum Priority : String, CaseIterable {
            case none, low, medium, high
            var title : String { rawValue.camelCaseToWords() }
            var image : String {
                switch self {
                case .none:
                    "gauge.with.needle"
                case .low:
                    "gauge.low"
                case .medium:
                    "gauge.medium"
                case .high:
                    "gauge.high"
                }
            }
            var color : Color {
                switch self {
                case .none:
                        .primary
                case .low:
                        .green
                case .medium:
                        .yellow
                case .high:
                        .red
                }
            }
        }
        enum Status : String, CaseIterable {
            case notStarted, inProgress, waiting, stayed, completed, unableToComplete, cancelled
            var title : String { rawValue.camelCaseToWords() }
        }
    }
}

extension Case.Task {
    init(text:String) {
        self = Case.Task(id: UUID().uuidString,
                         parentID: "",
                         fileIDs: [],
                         contactIDs: [],
                         tagIDs: [],
                         assigned: [],
                         priority: .none,
                         status: .notStarted,
                         isFlagged: false,
                         text: text)
    }
    
}

extension Case.Task : SheetRow {
    var sheetID: Int { Case.Sheet.tasks.intValue }
    
    init?(rowData: GTLRSheets_RowData) {
        guard let values = rowData.values else { return nil }
        guard values.count  >= 11 else { return nil }
        guard let id         = values[0].formattedValue else { return nil }
        guard let parentID   = values[2].formattedValue else { return nil }
        guard let fileIDs    = values[3].formattedValue else { return nil }
        guard let contactIDs = values[4].formattedValue else { return nil }
        guard let tagIDs     = values[5].formattedValue else { return nil }
        guard let assigned   = values[6].formattedValue else { return nil }
        guard let priString  = values[7].formattedValue,
                 let priorty = Priority(rawValue: priString) else { return nil }
        guard let staString  = values[8].formattedValue,
                 let status  = Status(rawValue: staString) else { return nil }
        guard let isFString  = values[9].formattedValue,
               let isFlagged = Bool(string:isFString) else  { return nil }
        guard let text       = values[10].formattedValue else { return nil }

        let dueDateString    = values.count >= 12 ? values[11].formattedValue : nil
       
        let note             = values.count >= 13 ? values[12].formattedValue : nil

        self.id          = id
        self.parentID    = parentID
        self.fileIDs     = fileIDs.commify
        self.contactIDs  = contactIDs.commify
        self.tagIDs      = tagIDs.commify
        self.assigned    = assigned.commify
        self.priority    = priorty
        self.status      = status
        self.isFlagged   = isFlagged
        
        
        self.text       = text
        dueDate = Date(string: dueDateString ?? "")
        self.note       = note
        
    }

    
    var cellData: [GTLRSheets_CellData] {[
        Self.stringData(id),
        Self.stringData(parentID),
        Self.stringData(fileIDs.commify),
        Self.stringData(contactIDs.commify),
        Self.stringData(tagIDs.commify),
        Self.stringData(assigned.commify),
        Self.stringData(priority.rawValue),
        Self.stringData(status.rawValue),
        Self.stringData(isFlagged.string),
        Self.stringData(text),
        Self.stringData(dueDate?.yyyymmdd),
        Self.stringData(note)
    ]}
}
