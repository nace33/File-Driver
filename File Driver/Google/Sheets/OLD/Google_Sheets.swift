//
//  Google_Sheets.swift
//  Cases
//
//  Created by Jimmy Nasser on 8/21/23.
//

import Foundation
import GoogleAPIClientForREST_Sheets

@Observable
final class Google_Sheets {
    static let shared: Google_Sheets = { Google_Sheets() }() //Singleton
    let service =  GTLRSheetsService()
    let scopes  =  [kGTLRAuthScopeSheetsSpreadsheets]
}

//MARK: Spreadsheets
extension Google_Sheets {
    func create(_ spreadsheet:GTLRSheets_Spreadsheet) async throws -> GTLRSheets_Spreadsheet {
        do {
            let fetcher = Google_Fetcher<GTLRSheets_Spreadsheet>(service:service, scopes:scopes)
            let query   = GTLRSheetsQuery_SpreadsheetsCreate.query(withObject: spreadsheet)
            
        
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    func initialize(id:String, gtlrSheets:[GTLRSheets_Sheet]) async throws {
        do {
            let spreadsheet = try await getSpreadsheet(id: id)
            let update = GTLRSheets_BatchUpdateSpreadsheetRequest()
            var requests = [GTLRSheets_Request]()

            if let existingIDs = spreadsheet.sheets?.compactMap({ $0.properties?.sheetId }) {
                let updateSheets = gtlrSheets.filter { existingIDs.contains($0.properties?.sheetId ?? NSNumber(value: 0))}
         
                for sheet in updateSheets {
                    let request = GTLRSheets_Request()
                    let updateSheetRequest = GTLRSheets_UpdateSheetPropertiesRequest()
                    updateSheetRequest.fields = "*"
                    let properties = GTLRSheets_SheetProperties()
                    properties.title = sheet.properties?.title ?? "Untitled"
                
                    properties.gridProperties = sheet.properties?.gridProperties
                    updateSheetRequest.properties = properties
                    
                    request.updateSheetProperties = updateSheetRequest
                    requests.append(request)
                }
                
                let addSheets    = gtlrSheets.filter { !updateSheets.contains($0)}
                for sheet in addSheets {
                    let request = GTLRSheets_Request()
                    let addSheetRequest = GTLRSheets_AddSheetRequest()
                    addSheetRequest.properties = sheet.properties
                    request.addSheet = addSheetRequest
                    requests.append(request)
                }
            }
            update.requests = requests
            let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: update, spreadsheetId: id)
            let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateSpreadsheetResponse>(service:service, scopes:scopes)

            _ = try await Google.execute(query, fetcher: fetcher)
            
        } catch {
            throw error
        }
    }
    func getSpreadsheet(id:String) async throws -> GTLRSheets_Spreadsheet {
        let fetcher = Google_Fetcher<GTLRSheets_Spreadsheet>(service:service, scopes:scopes)
        
        let query = GTLRSheetsQuery_SpreadsheetsGet.query(withSpreadsheetId: id)

        do {
           return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    func getSheets(spreadsheetID:String) async throws -> [GTLRSheets_Sheet] {
        do {
            let result = try await getSpreadsheet(id: spreadsheetID)
            return result.sheets ?? []
        } catch {
            throw error
        }
       
    }
    func getSheet(spreadsheetID:String, name:String) async throws -> GTLRSheets_Sheet {
        do {
            let sheets = try await getSheets(spreadsheetID: spreadsheetID)
            guard let sheet = sheets.first(where: {  $0.properties?.title?.lowercased() == name.lowercased() }) else {
                throw Google_Error.sheetNotFound(name, sheets.compactMap({$0.properties?.title ?? ""}))
            }
            return sheet
        } catch {
            throw error
        }
    }
    
}


//MARK: -GET
extension Google_Sheets {
    //Row Numbers
    func getRowNumbers(spreadsheetID:String, sheetName:String, rowIDs:[String], a1Offset:Bool = true) async throws -> [(id:String, index:Int)] {
        let fetcher = Google_Fetcher<GTLRSheets_ValueRange>(service:service, scopes:scopes)

        let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId:spreadsheetID, range: sheetName)
        query.majorDimension = kGTLRSheets_ValueRange_MajorDimension_Rows
        query.valueRenderOption = kGTLRSheetsValueRenderOptionFormattedValue
        
        var result = [(id:String, index:Int)]()
        
        do {
            let valueRange = try await Google.execute(query, fetcher: fetcher)
            if let values = valueRange.values,
                let ids = values.map({$0.first}) as? [String] {
                ids.enumerated().forEach { item in
                    if rowIDs.contains(item.element) {
                        result.append((item.element, a1Offset ? item.offset + 1 : item.offset))
                    }
                }
                return result.count == rowIDs.count ? result : []

            }
            throw Google_Error.driveCallSuceededButReturnTypeDoesNotMatch
        } catch {
            throw error
        }
    }
    func getRowNumber(spreadsheetID:String, sheetName:String, rowID:String, a1Offset:Bool = true) async throws -> Int {
        do {
            if let values = try await getRowNumbers(spreadsheetID: spreadsheetID, sheetName: sheetName, rowIDs: [rowID], a1Offset: a1Offset).first?.index {
                return values
            }
            throw Google_Error.driveCallSuceededButReturnTypeDoesNotMatch
        } catch {
            throw error
        }
        
    }

    //Values
    func getValues(spreadsheetID:String, ranges:[String], removeHeader:Bool = true, dimension:String = kGTLRSheets_ValueRange_MajorDimension_Rows) async throws -> [(range:String, values:[[String]])] {
        
        let query = GTLRSheetsQuery_SpreadsheetsValuesBatchGet.query(withSpreadsheetId: spreadsheetID)
        query.majorDimension = dimension
        query.valueRenderOption = kGTLRSheetsValueRenderOptionFormattedValue
        query.ranges = ranges
        
        let fetcher = Google_Fetcher<GTLRSheets_BatchGetValuesResponse>(service:service, scopes:scopes)

        do {
            let result = try await Google.execute(query, fetcher: fetcher)
            if let valueRanges = result.valueRanges {
                var allResults = [(range:String, values:[[String]])]()
                for valueRange in valueRanges {
                    if let range = valueRange.range,
                       let values = valueRange.values as? [[String]] {
                        if removeHeader && values.count > 0 {
                            allResults.append((range, Array(values.suffix(from: 1))))
                        } else {
                            allResults.append((range, values))
                        }
                    }
                }
                return  allResults
            }
            throw Google_Error.driveCallSuceededButReturnTypeDoesNotMatch

        } catch {
            throw error
        }

    }
    func getValues(spreadsheetID:String, range:String, removeHeader:Bool = true, dimension:String = kGTLRSheets_ValueRange_MajorDimension_Rows) async throws -> [[String]] {
        do {
            if let values = try await getValues(spreadsheetID: spreadsheetID, ranges: [range], removeHeader: removeHeader, dimension: dimension).first?.values {
                return values
            }
            throw Google_Error.driveCallSuceededButReturnTypeDoesNotMatch
        } catch {
            throw error
        }
    }
}

//MARK: -VERIFY
extension Google_Sheets {
    func verifyHeaders(id:String, sheetName:String, headers:[String]) async throws -> Bool {
    do {
        if let values = try  await Google_Sheets.shared.getValues(spreadsheetID: id, range: "\(sheetName)!1:1", removeHeader: false).first {
            return values.map({$0.lowercased()}).containsSameElementsInSameOrder(as: headers.map({$0.lowercased()}))
        }
        throw Google_Error.driveCallSuceededButReturnTypeDoesNotMatch
    } catch {
        throw error
    }

}
}


//MARK: -Append
extension Google_Sheets {
    func append(spreadsheetID:String, sheetName:String, row:[String]) async throws -> Bool {
        guard !row.isEmpty else { return false }
       
        let valueRange = GTLRSheets_ValueRange()
        valueRange.majorDimension = kGTLRSheets_ValueRange_MajorDimension_Rows
        valueRange.range = sheetName
        valueRange.values = [row]
        
        let query = GTLRSheetsQuery_SpreadsheetsValuesAppend.query(withObject: valueRange, spreadsheetId: spreadsheetID, range: sheetName)
        query.valueInputOption = kGTLRSheetsValueInputOptionRaw

        let fetcher = Google_Fetcher<GTLRSheets_AppendValuesResponse>(service:service, scopes:scopes)
        
        do {
            _ = try await Google.execute(query, fetcher: fetcher)
            return true

        } catch {
            throw error
        }
    }
    func append(spreadsheetID:String, rows:[(sheetName:String, values:[String])]) async throws -> Bool {
        do {
            let spreadsheet = try await getSpreadsheet(id: spreadsheetID)
            let mappedRows : [(sheetID:NSNumber, values:[String])] = rows.compactMap { row in
                if let sheet = spreadsheet.sheets?.first(where: {  $0.properties?.title == row.sheetName }),
                   let sheetID = sheet.properties?.sheetId {
                    return (sheetID, row.values)
                }
                return nil
            }
            guard mappedRows.count == rows.count else {
                print("Unable to locate at least one sheetID.")
                return false
            }
            let uniqueIDs = mappedRows.map { $0.sheetID }.unique()

            
            let update = GTLRSheets_BatchUpdateSpreadsheetRequest()
            
            var requests = [GTLRSheets_Request]()
            //Process by sheet
            for sheetID in uniqueIDs {
                let request = GTLRSheets_Request()
                let append  = GTLRSheets_AppendCellsRequest()
                append.fields = "*"
                append.sheetId = sheetID
                append.rows = mappedRows.filter( { $0.sheetID == sheetID }).compactMap { sheetRow in
                    let rowData = GTLRSheets_RowData()
                    rowData.values = sheetRow.values.compactMap { value in
                        let cellData = GTLRSheets_CellData()
                        let userData = GTLRSheets_ExtendedValue()
                        userData.stringValue = value
                        cellData.userEnteredValue = userData
                        return cellData
                    }
                    return rowData
                }
                request.appendCells = append
                requests.append(request)
            }
            update.requests = requests
            
            let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: update, spreadsheetId: spreadsheetID)
            let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateSpreadsheetResponse>(service:service, scopes:scopes)

            _ = try await Google.execute(query, fetcher: fetcher)
            return true
        } catch {
            throw error
        }
        

    }
   
}


//MARK: -Update
extension Google_Sheets {
    func update(values:[String], rowID:String, sheetName:String, spreadsheetID:String) async throws -> Bool {
        do {
            let rowIndex = try await getRowNumber(spreadsheetID: spreadsheetID, sheetName: sheetName, rowID: rowID, a1Offset: true)
        
            let range = "\(sheetName)!\(rowIndex):\(rowIndex)"
            
            let valueRange = GTLRSheets_ValueRange()
            valueRange.majorDimension = kGTLRSheets_ValueRange_MajorDimension_Rows
            valueRange.range = range
            valueRange.values = [values]
            
            let query = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange, spreadsheetId: spreadsheetID, range: range)
            query.valueInputOption = kGTLRSheetsValueInputOptionRaw
            let fetcher = Google_Fetcher<GTLRSheets_UpdateValuesResponse>(service:service, scopes:scopes)

            
            _ = try await Google.execute(query, fetcher: fetcher)
            return true
        } catch {
            throw error
        }
    }
    func update(spreadsheetID:String, rows:[(sheetName:String, row:Int, values:[String])]) async throws -> Bool {
        do {
            let request = GTLRSheets_BatchUpdateValuesRequest()
            request.valueInputOption = kGTLRSheets_BatchUpdateValuesRequest_ValueInputOption_Raw
            
            request.data = rows.compactMap({ tuple in
                let valueRange = GTLRSheets_ValueRange()
                valueRange.majorDimension = kGTLRSheets_ValueRange_MajorDimension_Rows
                valueRange.range = "\(tuple.sheetName)!A\(tuple.row)"
                valueRange.values = [tuple.values]
                return valueRange
            })
            
            let query = GTLRSheetsQuery_SpreadsheetsValuesBatchUpdate.query(withObject: request, spreadsheetId:spreadsheetID)
            let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateValuesResponse>(service:service, scopes:scopes)
            _ = try await Google.execute(query, fetcher: fetcher)
            return true
        } catch {
            throw error
        }

    }
    func update(spreadsheetID:String, rows:[(range:String, values:[String])]) async throws -> Bool {
        do {
            let request = GTLRSheets_BatchUpdateValuesRequest()
            request.valueInputOption = kGTLRSheets_BatchUpdateValuesRequest_ValueInputOption_Raw
            
            request.data = rows.compactMap({ tuple in
                let valueRange = GTLRSheets_ValueRange()
                valueRange.majorDimension = kGTLRSheets_ValueRange_MajorDimension_Rows
                valueRange.range = tuple.range
                valueRange.values = [tuple.values]
                return valueRange
            })
            
            let query = GTLRSheetsQuery_SpreadsheetsValuesBatchUpdate.query(withObject: request, spreadsheetId:spreadsheetID)
            let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateValuesResponse>(service:service, scopes:scopes)
            _ = try await Google.execute(query, fetcher: fetcher)
            return true
        } catch {
            throw error
        }

    }
    
}

//MARK: - Move
extension Google_Sheets {
//    func move(spreadsheetID:String, sheetName:String, rowID:String, to destination:Int, a1Offset:Bool = true) async throws -> Bool {
//        do {
//            let sheet = try await getSheet(spreadsheetID:spreadsheetID, name:sheetName)
//            let row   = try await getRowNumber(spreadsheetID:spreadsheetID, sheetName: sheetName, rowID:rowID, a1Offset: a1Offset)
//            return try await move(spreadsheetID: spreadsheetID, sheet: sheet, startRow: row - 1, endRow: row, destination:destination)
//        } catch {
//            throw error
//        }
//    }
    func move(spreadsheetID:String, sheet:GTLRSheets_Sheet, startRow:Int, endRow:Int, destination:Int) async throws -> Bool {
        guard let sheetID = sheet.properties?.sheetId, startRow >= 0 else { throw Google_Error.didNotProvidePropertiesToMethod(#function) }
        
        let dimensionRequest = GTLRSheets_MoveDimensionRequest()
        let range = GTLRSheets_DimensionRange()
        range.sheetId = sheetID
        range.startIndex = (startRow) as NSNumber
        range.endIndex = (endRow) as NSNumber
        range.dimension = kGTLRSheets_DimensionRange_Dimension_Rows
        dimensionRequest.destinationIndex = (destination) as NSNumber
        dimensionRequest.source = range
        
//        print("Moving Row: \(startRow) through \(endRow) to: \(destination)")

        let updateRequest = GTLRSheets_BatchUpdateSpreadsheetRequest()
        let sheetRequest = GTLRSheets_Request()
        sheetRequest.moveDimension = dimensionRequest
        updateRequest.requests = [sheetRequest]

        
        let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: updateRequest, spreadsheetId: spreadsheetID)
       
        let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateSpreadsheetResponse>(service:service, scopes:scopes)
        do {

            _ = try await Google.execute(query, fetcher: fetcher)
            return true
        } catch {
            throw error
        }

    }
    func move(spreadsheetID:String, sheetName:String, rowID:String, to destination: Int, a1Offset:Bool = true) async throws -> Bool{

        do {
            let row   = try await Google_Sheets.shared.getRowNumber(spreadsheetID: spreadsheetID, sheetName:sheetName, rowID:rowID, a1Offset: a1Offset)
            let sheet = try await Google_Sheets.shared.getSheet(spreadsheetID: spreadsheetID, name:sheetName)
            _ = try await Google_Sheets.shared.move(spreadsheetID: spreadsheetID,
                                                    sheet:sheet,
                                                    startRow: row - 1,
                                                    endRow: row ,
                                                    destination: destination + 1)
            return true
        } catch {
            throw error
        }
    }

}

//MARK: - Delete
extension Google_Sheets {
    func delete(row:Int, spreadsheetID:String, sheetID:NSNumber) async throws -> Bool {
        print(#function)
        guard row >= 0 else { throw Google_Error.didNotProvidePropertiesToMethod(#function) }
        
        
        let updateRequest = GTLRSheets_BatchUpdateSpreadsheetRequest()
        
        let sheetRequest = GTLRSheets_Request()
        let deleteDimension = GTLRSheets_DeleteDimensionRequest()
    
        let deleteRange = GTLRSheets_DimensionRange()
        deleteRange.dimension = kGTLRSheets_DimensionRange_Dimension_Rows
 
        deleteRange.sheetId    = sheetID
        deleteRange.startIndex = (row) as NSNumber
        deleteRange.endIndex   = (row + 1) as NSNumber
     
        deleteDimension.range = deleteRange
    
        
        sheetRequest.deleteDimension = deleteDimension
        
        updateRequest.requests = [sheetRequest]
        
        let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: updateRequest, spreadsheetId: spreadsheetID)
       
        let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateSpreadsheetResponse>(service:service, scopes:scopes)
        do {

            _ = try await Google.execute(query, fetcher: fetcher)
            return true
        } catch {
            throw error
        }
    }
    //Convenience
    func delete(rowID:String, sheetName:String, spreadsheetID:String) async throws -> Bool {
        do {
            let row = try await getRowNumber(spreadsheetID:spreadsheetID, sheetName:sheetName, rowID: rowID, a1Offset: false)
            let sheet = try await getSheet(spreadsheetID:spreadsheetID, name:sheetName)
            guard try await delete(row: row, spreadsheetID:spreadsheetID, sheetID: sheet.properties?.sheetId ?? 0) else {
                throw Google_Error.driveCallSuceededButReturnTypeDoesNotMatch
            }
            return true

        } catch {
            print(#function + " " + error.localizedDescription)
            throw error
        }
       
    }
    //Multiple
    func delete(spreadsheetID:String, rows:[(sheetID:NSNumber, index:Int)]) async throws -> Bool {
        guard rows.count >= 0 else { throw Google_Error.didNotProvidePropertiesToMethod(#function)  }
        
        
        let updateRequest = GTLRSheets_BatchUpdateSpreadsheetRequest()
        
        var requests = [GTLRSheets_Request]()
        for row in rows {
            let sheetRequest = GTLRSheets_Request()
            let deleteDimension = GTLRSheets_DeleteDimensionRequest()
        
            let deleteRange = GTLRSheets_DimensionRange()
            deleteRange.dimension = kGTLRSheets_DimensionRange_Dimension_Rows
            deleteRange.sheetId    = row.sheetID
            deleteRange.startIndex = (row.index) as NSNumber
            deleteRange.endIndex   = (row.index + 1) as NSNumber
         
            deleteDimension.range = deleteRange
        
            
            sheetRequest.deleteDimension = deleteDimension
            requests.append(sheetRequest)
        }

        
        updateRequest.requests = requests
        
        let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: updateRequest, spreadsheetId: spreadsheetID)
       
        let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateSpreadsheetResponse>(service:service, scopes:scopes)

        do {
            _ = try await Google.execute(query, fetcher: fetcher)
            return true
        } catch {
            throw error
        }

    }
}


//MARK: -Clear Values
extension Google_Sheets {
    func clear(rowID:String, sheetName:String, spreadsheetID:String) async throws -> Bool {
        do {
            let rowIndex = try await getRowNumber(spreadsheetID: spreadsheetID, sheetName: sheetName, rowID: rowID, a1Offset: true)
            let request = GTLRSheets_ClearValuesRequest()
            let range = "\(sheetName)!\(rowIndex):\(rowIndex)"
            let query = GTLRSheetsQuery_SpreadsheetsValuesClear.query(withObject: request, spreadsheetId: spreadsheetID, range: range)
            
            let fetcher = Google_Fetcher<GTLRSheets_ClearValuesResponse>(service:service, scopes:scopes)
            
            _ = try await Google.execute(query, fetcher: fetcher)
            return true
        } catch {
            throw error
        }
        

   
    }
}

