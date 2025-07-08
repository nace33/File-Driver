//
//  Case.Folder.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import Foundation
import BOF_SecretSauce
import GoogleAPIClientForREST_Drive
extension Case {
    struct Folder : Identifiable, Hashable {
        var id      : String { folderID}
        var folderID : String
        var name     : String
        var note    : String?
        
    }
}

extension Case.Folder {
    init?(file:GTLRDrive_File, note:String? = nil) {
        guard file.isFolder else { return nil }
        self.folderID = file.id
        self.name     = file.name ?? "Untitled Folder"
        self.note     = note
    }
}


import GoogleAPIClientForREST_Sheets
extension Case.Folder : SheetRow {
    var sheetID: Int { Case.Sheet.folders.intValue }
    
    init?(rowData: GTLRSheets_RowData) {
        guard let values = rowData.values else { return nil }
        guard values.count  >= 2 else { return nil }
        guard let folderID   = values[0].formattedValue else { return nil }
        guard let name       = values[1].formattedValue else { return nil }
    
        //Optionals
        let note       = values.count >= 3 ? values[2].formattedValue : nil

        self.folderID  = folderID
        self.name      = name
        self.note      = note
    }

    var cellData: [GTLRSheets_CellData] {[
        Self.stringData(folderID),
        Self.stringData(name),
        Self.stringData(note)
    ]}
}


