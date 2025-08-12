//
//  Case.Tag.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import SwiftUI

extension Case {
    struct Tag : Identifiable, Hashable {
        let id       : String
        let name     : String
        let note     : String?
  
    }
}



import GoogleAPIClientForREST_Sheets
extension Case.Tag : GoogleSheetRow {
    var sheetID: Int { Case.Sheet.tags.intValue }
    var sheetName : String { Case.Sheet.tags.rawValue}

    init?(rowData: GTLRSheets_RowData) {
        guard let values = rowData.values else { return nil }
        guard values.count  >= 2 else { return nil }
        guard let id        = values[0].formattedValue else { return nil }
        guard let name      = values[1].formattedValue else { return nil }
        //Optionals
        let note         = values.count >= 3 ? values[2].formattedValue : nil

        self.id         = id
        self.name       = name
        self.note       = note
    }

    
    var cellData: [GTLRSheets_CellData] {[
        Self.stringData(id),
        Self.stringData(name),
        Self.stringData(note)
    ]}
}
