//
//  GTLRSpreadsheet.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/25/25.
//

import Foundation
import GoogleAPIClientForREST_Sheets


extension GTLRSheets_Spreadsheet {
    func rowData(range:String, dropHeader:Bool = true) -> [GTLRSheets_RowData]? {
        guard let sheet = sheets?.first(where: {$0.properties?.title?.lowercased() == range.lowercased()}) else { return nil }
        guard var rowData = sheet.rowDataArray else { return nil }
        if dropHeader {
            rowData.removeFirst()
        }
        return rowData
    }
    func rowValues(range:String, dropHeader:Bool = true) -> [GTLRSheets_CellData]? {
        guard let rowData = rowData(range:range, dropHeader:dropHeader) else { return nil }
        var rowValues  = [GTLRSheets_CellData]()
        for row in rowData {
            if let values = row.values {
                rowValues.append(contentsOf: values)
            }
        }
        return rowValues
    }
    
    enum Field : String, CaseIterable {
        case sheetTitle     = "properties(title)"//also works as "sheets(properties(title))"
        case chipRuns       = "data.rowData.values(formattedValue,chipRuns)"
    }
}


