//
//  Sheets.Requests.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/12/25.
//

import Foundation
import GoogleAPIClientForREST_Sheets





//MARK: - Sheet Rows
extension Sheets {
    func requests(append sheetRows:[any GoogleSheetRow]) -> [GTLRSheets_Request] {
        var requests = [GTLRSheets_Request]()
        
        let sheetIDs = sheetRows.compactMap { $0.sheetID }.unique()
        for sheetID in sheetIDs {
            let rows = sheetRows.filter { $0.sheetID == sheetID}

            let request = GTLRSheets_Request()
            let append  = GTLRSheets_AppendCellsRequest()
            append.fields = "userEnteredValue"
            append.sheetId = NSNumber(value: sheetID)
            append.rows = rows.compactMap(\.rowData)
            request.appendCells = append
            requests.append(request)
        }
        return requests
    }
    func requests(update sheetRowPairs:[(any GoogleSheetRow, Int)]) -> [GTLRSheets_Request] {
        var requests : [GTLRSheets_Request] = []
        let sheetIDs = sheetRowPairs.compactMap { $0.0.sheetID }.unique()

        for sheetID in sheetIDs {
            let pairsForSheet = sheetRowPairs.filter { $0.0.sheetID == sheetID }
            for rowPair in pairsForSheet {
                let request         = GTLRSheets_Request()
                let update          = GTLRSheets_UpdateCellsRequest()
                update.fields       = "userEnteredValue"
                let range           = GTLRSheets_GridRange()
                range.sheetId       = NSNumber(value:sheetID)
                range.startRowIndex = NSNumber(value:rowPair.1)
                range.endRowIndex   = NSNumber(value:rowPair.1 + 1)//without this it will delete everything between lowest and highest row where a value is not supplied.
                update.range        = range
                let rowData         = GTLRSheets_RowData()
                rowData.values      = rowPair.0.rowData.values
                update.rows = [rowData]
                request.updateCells = update
                requests.append(request)
            }
        }
        return requests
    }
}


//MARK: - Find and Replace
extension Sheets {
    func requests(find string:String, replace:String, sheetID:Int?) -> [GTLRSheets_Request] {
        let request     = GTLRSheets_Request()
        let fR          = GTLRSheets_FindReplaceRequest()
    
        fR.find         = string
        fR.replacement  = replace

        //Set the scope of the search/replace.
        //1. All Sheets (.allSheets = true)
        //2. A specific Sheet (.sheetId = X); or
        //3 A specific range in a sheet
        
        if let sheetID {
            fR.sheetId = sheetID as NSNumber
        } else {
            fR.allSheets = true
        }
  
        request.findReplace = fR
        
        var requests = [GTLRSheets_Request]()
        requests.append(request)
        return requests
    }
}


//MARK: - Formatting
extension Sheets {
    func requests(wrap:WrapStrategy? = nil, vertical:Vertical? = nil, horizontal:Horizontal? = nil, sheets:[Int]) -> [GTLRSheets_Request] {
        var requests = [GTLRSheets_Request]()
        for sheet in sheets {
            let gridRange               = GTLRSheets_GridRange()
            gridRange.sheetId           = NSNumber(value: sheet)
            
            let cellData = GTLRSheets_CellData()
            cellData.userEnteredFormat = GTLRSheets_CellFormat()
            var fields : [String] = []
            if let wrap {
                cellData.userEnteredFormat?.wrapStrategy         = wrap.rawValue
                fields.append("wrapStrategy")
            }
            if let vertical {
                cellData.userEnteredFormat?.verticalAlignment    = vertical.rawValue
                fields.append("verticalAlignment")
            }
            if let horizontal {
                cellData.userEnteredFormat?.horizontalAlignment  = horizontal.rawValue
                fields.append("horizontalAlignment")
            }

            let repeatCellsRequest      = GTLRSheets_RepeatCellRequest()
            repeatCellsRequest.fields   = "userEnteredFormat(\(fields.joined(separator: ",")))"
            repeatCellsRequest.range    = gridRange
            repeatCellsRequest.cell     = cellData
            
            let request = GTLRSheets_Request()
            request.repeatCell = repeatCellsRequest
            requests.append(request)
        }
        return requests
    }
    func requests(for namedRanges:[GTLRSheets_NamedRange]) -> [GTLRSheets_Request] {
        let namedRangeRequests : [GTLRSheets_AddNamedRangeRequest] = namedRanges.compactMap { namedRange in
            let namedRangeRequest = GTLRSheets_AddNamedRangeRequest()
            namedRangeRequest.namedRange = namedRange
            return namedRangeRequest
        }
    
        let requests : [GTLRSheets_Request] = namedRangeRequests.compactMap { namedRangeRequest in
            let request = GTLRSheets_Request()
            request.addNamedRange = namedRangeRequest
            return request
        }
        return requests
    }
}


