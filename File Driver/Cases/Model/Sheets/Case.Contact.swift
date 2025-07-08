//
//  Case.Contact.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import Foundation
import GoogleAPIClientForREST_Drive


extension Case {
    struct Contact : Identifiable {
        let id         : String
        let centralID  : String?
        let folderID   : String?
        let name       : String
        let role       : String?
        let isClient   : Bool
        let note       : String?
    }
}


extension Case.Contact : Hashable {
    init(name:String) {
        self.id = UUID().uuidString
        self.centralID  = nil
        self.folderID   = nil
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.role = nil
        self.isClient = false
        self.note = nil
    }
}


import GoogleAPIClientForREST_Sheets
extension Case.Contact : SheetRow {
    var sheetID: Int { Case.Sheet.contacts.intValue }
    
    init?(rowData: GTLRSheets_RowData) {
        guard let values = rowData.values else { return nil }
        guard values.count  >= 6 else { return nil }
        guard let id         = values[0].formattedValue else { return nil }
        let centralID        = values[1].formattedValue
        let folderID         = values[2].formattedValue
        guard let name       = values[3].formattedValue else { return nil }
        let role             = values[4].formattedValue
        guard let clientStr  = values[5].formattedValue else { return nil }
        guard let isClient   = Bool(string: clientStr)  else { return nil }

        //Optionals
        let note         = values.count >= 7 ? values[6].formattedValue  : nil

        self.id         = id
        self.centralID  = centralID
        self.folderID   = folderID
        self.name       = name
        self.role       = role
        self.isClient   = isClient
        self.note       = note
    }
    


    var cellData: [GTLRSheets_CellData] {[
        Case.Contact.stringData(id),
        Case.Contact.stringData(centralID),
        Case.Contact.stringData(folderID),
        Case.Contact.stringData(name),
        Case.Contact.stringData(role),
        Case.Contact.stringData(isClient.string),
        Case.Contact.stringData(note)
    ]}
}
