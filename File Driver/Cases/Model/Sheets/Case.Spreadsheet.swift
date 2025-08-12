//
//  Case.Sheet.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import Foundation
import BOF_SecretSauce
import GoogleAPIClientForREST_Sheets

extension Case {
    static var spreadsheetVersion : String { "FileDriver.Case.Sheet.v2.0.0" }
    enum Sheet : String, CaseIterable, GoogleSheet {
        
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
       
        var columns : [any GoogleSheetColumn] {Column.columns(for:self)}

        var namedRanges : [GTLRSheets_NamedRange] {
            switch self {
            case .contacts:
                if let namedRange = Sheet.namedRange("Contacts", sheet: self, column: Column.name){
                    return [namedRange]
                }
                return []
            case .contactData:
                return []
            case .tags:
                if let namedRange = Sheet.namedRange("Tags", sheet: self, column: Column.name){
                    return [namedRange]
                }
                return []
            case .folders:
                if let namedRange = Sheet.namedRange("Folders", sheet: self, column: Column.name){
                    return [namedRange]
                }
                return []
            case .files:
                return []
            case .tasks:
                return []
            case .trackers:
                return []
            }
        }
    }
    
    enum Column : String, CaseIterable, GoogleSheetColumn {
        
        
        case id, centralID, folderID, name, role, isClient, note
        case contactID, category, label, value
        case folderIDs, fileID, mimeType, contactIDs, tagIDs, snippet, idDateString, fileSize
        case dueDate, priority, status, text, assignedTo, fileIDs
        case parentID, isFlagged
        case threadID, createdBy, isHidden
        
        static func columns(for sheet: any GoogleSheet) -> [Case.Column] {
            guard let daSheet = sheet as? Case.Sheet else { return [] }
            return switch daSheet {
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
}


