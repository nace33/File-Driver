//
//  ContactData.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//


extension Case {
    struct ContactData : Identifiable, Hashable {
        let id          : String
        let contactID   : String
        let category    : String
        let label       : String
        let value       : String
        let note        : String?
    
    }
}




import GoogleAPIClientForREST_Sheets
extension Case.ContactData : SheetRow {
    var sheetID: Int { Case.Sheet.contactData.intValue }
    
    init?(rowData: GTLRSheets_RowData) {
        guard let values = rowData.values else { return nil }
        guard values.count  >= 5 else { return nil }
        guard let id         = values[0].formattedValue else { return nil }
        guard let contactID  = values[1].formattedValue else { return nil }
        guard let category   = values[2].formattedValue else { return nil }
        guard let label      = values[3].formattedValue else { return nil }
        guard let value      = values[4].formattedValue else { return nil }
        //Optionals
        let note         = values.count >= 6 ? values[5].formattedValue : nil

        self.id         = id
        self.contactID  = contactID
        self.category   = category
        self.label      = label
        self.value      = value
        self.note       = note
    }

    
    var cellData: [GTLRSheets_CellData] {[
        Self.stringData(id),
        Self.stringData(contactID),
        Self.stringData(category),
        Self.stringData(label),
        Self.stringData(value),
        Self.stringData(note)
    ]}
}
