//
//  File.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/25/25.
//
import Foundation
import GoogleAPIClientForREST_Sheets

extension GTLRSheets_Sheet {
    
    var rowDataArray : [GTLRSheets_RowData]? {
        guard let gridDataArray = data else { return nil }
        var rowDataArray = [GTLRSheets_RowData]()
        for gridData in gridDataArray {
            for rowData in gridData.rowData ?? [] {
                rowDataArray.append(rowData)
            }
        }
        return rowDataArray
    }
    var rowValues : [GTLRSheets_CellData]?  {
        guard let rowDataArray else { return nil }
        var values = [GTLRSheets_CellData]()
        for rowData in rowDataArray {
            if let cellDataArray = rowData.values {
                values.append(contentsOf: cellDataArray)
            }
        }
        return values
    }
}
