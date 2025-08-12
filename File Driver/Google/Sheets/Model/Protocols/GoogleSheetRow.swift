
//
//  Sheet.Row.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/25/25.
//

import Foundation
import GoogleAPIClientForREST_Sheets
import GoogleAPIClientForREST_Drive


//MARK: - Protocol
protocol GoogleSheetRow : Identifiable, Sendable {
    var sheetID : Int                    { get }
    var sheetName : String               { get }
    init?(rowData:GTLRSheets_RowData)
    var rowData : GTLRSheets_RowData     { get }
    var cellData : [GTLRSheets_CellData] { get }
    
}

extension GoogleSheetRow {
    static func stringData(_ string:String?) -> GTLRSheets_CellData {
        guard let string else { return GTLRSheets_CellData()}
        let cellData = GTLRSheets_CellData()
        let userData = GTLRSheets_ExtendedValue()
        userData.stringValue = string
        cellData.userEnteredValue = userData
        return cellData
    }
    static func createFileChip  (_ fileID:String, mimeType:String?) -> GTLRSheets_CellData {
        /*  https://developers.google.com/workspace/sheets/api/guides/chips
            current client library does not have chipRuns
            setting the textFormatRuns to a GTLRSheets_TextFormatRun does NOT work
            It just creates a hyperlink, not a file-chip.
            add custom json to make this work
        */
        let cellData = GTLRSheets_CellData()
        let uri = Sheets.FileChip.createDriveURI(fileID, mimeType: mimeType)
        let userValue = GTLRSheets_ExtendedValue()
        userValue.stringValue = "@"
        cellData.userEnteredValue = userValue
        
        let fileChipDictionary : [String:Any] = [
            "startIndex": 0,
            "chip":["richLinkProperties":["uri":uri]]
        ]

        cellData.setJSONValue([fileChipDictionary], forKey: "chipRuns")
        return cellData
    }
    static func getFileChipRun(cellData:GTLRSheets_CellData) -> Sheets.FileChipRun? {
        let json = cellData.jsonString()
        let decoder = JSONDecoder()
        guard let data = json.data(using: .utf8),
              let chipRun = try? decoder.decode(Sheets.FileChipRun.self, from: data) else {
            return nil
        }
        return chipRun
    }
}


extension GoogleSheetRow {
    var rowData: GTLRSheets_RowData {
        let rowData = GTLRSheets_RowData()
        rowData.values = cellData
        return rowData
    }
}


