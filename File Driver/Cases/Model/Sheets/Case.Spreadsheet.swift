//
//  Case.Sheet.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import Foundation
import BOF_SecretSauce

extension Case {
    static var spreadsheetVersion : String { "FileDriver.Case.Sheet.v2.0.0" }
    enum Sheet : String, CaseIterable {
        case contacts, contactData
        case tags
        case folders, files
        case tasks
        case trackers
        
        var title : String {
            switch self {
            case .contacts:
                "Contacts"
            case .contactData:
                "ContactData"
            case .tags:
                "Tags"
            case .folders:
                "Folders"
            case .files:
                "Files"
            case .tasks:
                "Tasks"
            case .trackers:
                "Trackers"
            }
        }
        var intValue : Int {
            switch self {
            case .contacts:
                0
            case .contactData:
                1
            case .tags:
                2
            case .folders:
                3
            case .files:
                4
            case .tasks:
                5
            case .trackers:
                6
            }
        }
        static func sheet(_ intValue:Int) -> Sheet? {
            guard (0..<Self.allCases.count).contains(intValue) else { return nil }
            return Self.allCases.first(where: {$0.intValue == intValue})!
        }
        var valueRange : String {
            title + "!A2:\(intValue.letter.capitalized)"
        }
        var columns : [Column] {Column.columns(for:self)}
    
        var gtlrSheet : GTLRSheets_Sheet {
            let newSheet         = GTLRSheets_Sheet()
            
            //Set Sheet properties
            let properties       = GTLRSheets_SheetProperties()
            properties.index     = NSNumber(value: self.intValue)
            properties.sheetId   = NSNumber(value: self.intValue)
            properties.sheetType = kGTLRSheets_SheetProperties_SheetType_Grid
            properties.title     = self.title
            
            //set column and row dimensions
            properties.gridProperties = gtlrSheetGridProperties
            
            //add to Spreadsheet
            newSheet.properties = properties
            return newSheet
        }
        var gtlrSheetGridProperties : GTLRSheets_GridProperties {
            let columns          = self.columns
            let grid             = GTLRSheets_GridProperties()
            grid.columnCount     = NSNumber(value: columns.count)
            grid.frozenRowCount  = NSNumber(value: 1)
            grid.rowCount        = NSNumber(value: 1000)
            return grid
        }
      
        var namedRanges : [GTLRSheets_NamedRange] {
            switch self {
            case .contacts:
                return [Sheet.namedRange("Contacts", sheet: self, column: .name)]
            case .contactData:
                return []
            case .tags:
                return [Sheet.namedRange("Tags", sheet: self, column: .name)]
            case .folders:
                return [Sheet.namedRange("Folders", sheet: self, column: .name)]
            case .files:
                return []
            case .tasks:
                return []
            case .trackers:
                return []
            }
        }
        var headerRow : Sheets.Header {
            Sheets.Header(sheet: rawValue, names: columns.compactMap(\.rawValue))
        }
      
        static func namedRange(_ title:String, sheet:Sheet, column:Column) -> GTLRSheets_NamedRange {
            let namedRange = GTLRSheets_NamedRange()
            namedRange.name         = title
            namedRange.namedRangeId = title
            let range = GTLRSheets_GridRange()
            range.sheetId = NSNumber(value: sheet.intValue)
            let index = Column.columns(for: sheet).firstIndex(of: column)!
            range.startColumnIndex = NSNumber(value: index)
            range.endColumnIndex   = NSNumber(value: index + 1)
            range.startRowIndex    = NSNumber(value: 1)
            namedRange.range       = range
            return namedRange
        }
    }
    
    enum Column : String, CaseIterable {
        case id, centralID, folderID, name, role, isClient, note
        case contactID, category, label, value
        case folderIDs, fileID, mimeType, contactIDs, tagIDs, snippet, idDateString, fileSize
        case dueDate, priority, status, text, assignedTo, fileIDs
        case parentID, isFlagged
        case threadID, createdBy, isHidden
        static func columns(for sheet:Sheet) -> [Column] {
            switch sheet {
            case .contacts:
                [.id, .centralID, .folderID, .name, .role, .isClient, .note]
            case .contactData:
                [.id, .contactID, .category, .label, .value, .note]
            case .tags:
                [.id, .name, .note]
            case .folders:
                [.folderID, .name, .note]
            case .files:
                [.fileID, .name, .mimeType, .fileSize, .folderIDs, .contactIDs, .tagIDs, .idDateString, .snippet, .note]
            case .tasks:
                [.id, .parentID, .fileIDs, .contactIDs, .tagIDs, .assignedTo, .priority, .status, .isFlagged, .text, .dueDate, .note]
            case .trackers:
                [.id, .idDateString, .threadID, .contactIDs, .tagIDs, .fileIDs, .text, .category, .status, .createdBy, .isHidden]
            }
        }
    }
    
    struct Row  {
        var columns : [Column]
        var values  : [Column:String]
        var strings : [String]
        init?(sheet:Sheet, strings:[String]) {
            guard sheet.columns.count == strings.count else { return nil }
            self.columns = sheet.columns
            self.strings = strings
            var dict : [Column:String] = [:]
            for (index, column) in columns.enumerated() {
                dict[column] = strings[index]
            }
            self.values = dict
        }
    }
}

import GoogleAPIClientForREST_Sheets
extension Case {
    static func newGtlrSpreadsheet(title:String) -> GTLRSheets_Spreadsheet {
        let newSpreadsheet = GTLRSheets_Spreadsheet()
        let spreadsheetProperties = GTLRSheets_SpreadsheetProperties()
        spreadsheetProperties.title = title
        newSpreadsheet.properties = spreadsheetProperties
        
        
        newSpreadsheet.sheets      = Case.Sheet.allCases.compactMap { $0.gtlrSheet   }
        newSpreadsheet.namedRanges = Case.Sheet.allCases.flatMap    { $0.namedRanges }

        return newSpreadsheet
    }
}



