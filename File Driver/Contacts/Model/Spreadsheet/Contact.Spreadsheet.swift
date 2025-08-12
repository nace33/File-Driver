//
//  Contact.Spreadsheet.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/10/25.
//

import SwiftUI
import BOF_SecretSauce
import GoogleAPIClientForREST_Sheets

//MARK: - Sheets
public extension Contact {
    static var spreadsheetVersion : String { "FileDriver.Contact.Sheet.v2.0.0" }
    enum Sheet :String, CaseIterable, GoogleSheet {
        case  info, files
        var title : String {  rawValue.camelCaseToWords  }
        var columns : [any GoogleSheetColumn] {Column.columns(for:self)}
        var namedRanges : [GTLRSheets_NamedRange] { [] }
    }

    enum Column : String, CaseIterable, GoogleSheetColumn {
        static func columns(for sheet: any GoogleSheet) -> [Contact.Column] {
            guard let daSheet = sheet as? Contact.Sheet else {return []}
            return switch daSheet {
            case .info:
                Self.infoColumns
            case .files:
                Self.fileColumns
            }
        }
        
        //Info
        case id, dateID, category, label, value, note
        static var infoColumns : [Column] { [.id, .dateID, .category, .label, .value, .note] }
        
        //Files
        case fileID, filename, mimeType, fileSize
        static var fileColumns : [Column] { [.id, .dateID, .fileID, .category, .filename, .mimeType, .fileSize, .note]}  
    }
}
