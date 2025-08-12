//
//  Research.Spreadsheet.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import Foundation
import GoogleAPIClientForREST_Sheets


extension Research {
    static var spreadsheetVersion : String { "FileDriver.Case.Sheet.v2.0.0" }
    enum Sheet : String, CaseIterable, GoogleSheet {
        case authority, elements, facts, chat, files
        var title : String { rawValue.camelCaseToWords }
        var columns : [any GoogleSheetColumn] {Column.columns(for:self)}
        var namedRanges: [GTLRSheets_NamedRange] {[]}
    }
    
    enum Column : String, CaseIterable, GoogleSheetColumn {
        
        case id, dateID, title, citation, text , order, link, createdBy
        case authorityID, number, alternativeToNumber, isRequred
        case elementID,  source
        case fileID, filename, note

        
        static func columns(for sheet: any GoogleSheet) -> [Self] {
            guard let daSheet = sheet as? Research.Sheet else {  return []   }
            return switch daSheet {
            case .authority:
                [.id, .dateID, .title, .citation, .text, .order, .link, .createdBy]
            case .elements:
                [.id, .authorityID, .number, .alternativeToNumber, .isRequred, .text]
            case .facts:
                [.id, .elementID, .text, .source ]
            case .chat:
                [.id, .dateID, .createdBy, .text, .link ]
            case .files:
                [.id, .fileID, .dateID, .filename, .text, .note]
            }
        }
    }
}

