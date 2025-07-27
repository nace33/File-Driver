//
//  Case.Filing.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import Foundation
import GoogleAPIClientForREST_Sheets
import BOF_SecretSauce
//[.fileID, .name, .mimeType, .fileSize, .folderIDs, .contactIDs, .tagIDs, .idDateString, .snippet, .note]
extension Case {
    struct File : Identifiable, Hashable {
        var id            : String { fileID }
        var fileID        : String
        var name          : String
        var mimeType      : String
        var fileSize      : String
        var folderID      : String
        var contactIDs    : [String]
        var tagIDs        : [String]
        var idDateString  : String
        var snippet       : String?
        var note          : String?
        

        
        var filename : String {
            (name as NSString).deletingPathExtension
        }
 
        var fileExtension : String {
            (name as NSString).pathExtension
        }
    }
}



extension Case.File : SheetRow {
    var sheetID: Int { Case.Sheet.files.intValue }
    init?(rowData: GTLRSheets_RowData) {
        guard let values = rowData.values else { return nil }
        guard values.count  >= 8 else { return nil }
        guard let fileID     = values[0].formattedValue else { return nil }
        guard let name       = values[1].formattedValue else { return nil }
        guard let mimeType   = values[2].formattedValue else { return nil }
        guard let fileSize   = values[3].formattedValue else { return nil }
        guard let folderID   = values[4].formattedValue else { return nil }
        let contactIDs       = values[5].formattedValue  ?? ""
        let tagIDs           = values[6].formattedValue  ?? ""
        guard let idDate     = values[7].formattedValue else { return nil }

        let snippet          = values.count >= 9  ? values[8].formattedValue ?? "" : ""
        let note             = values.count >= 10 ? values[9].formattedValue ?? "" : ""
        
        self.fileID         = fileID
        self.name           = name
        self.mimeType       = mimeType
        self.fileSize       = fileSize
        self.folderID       = folderID
        self.contactIDs     = contactIDs.commify
        self.tagIDs         = tagIDs.commify
        self.idDateString   = idDate
        self.snippet        = snippet
        self.note           = note
    }

    var cellData: [GTLRSheets_CellData] {[
        Self.stringData(fileID),
        Self.stringData(name),
        Self.stringData(mimeType),
        Self.stringData(fileSize),
        Self.stringData(folderID),
        Self.stringData(contactIDs.commify),
        Self.stringData(tagIDs.commify),
        Self.stringData(idDateString),
        Self.stringData(snippet),
        Self.stringData(note)
    ]}
}


