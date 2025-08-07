//
//  Sheets.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/25/25.
//

import Foundation
import GoogleAPIClientForREST_Sheets

@Observable
final class Sheets {
    static let shared: Sheets = { Sheets() }() //Singleton
    let service =  GTLRSheetsService()
    let scopes  =  [kGTLRAuthScopeSheetsSpreadsheets]
}

extension Sheets {
    struct Header {
        let sheet:String
        let names:[Any]
    }
}

//MARK: - Create
extension Sheets {
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
            let spreadsheet = try await getSpreadsheet(id)
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
    func initialize(id:String, headers:[Sheets.Header]) async throws {
        do {
            let request              = GTLRSheets_BatchUpdateValuesRequest()
            request.valueInputOption = kGTLRSheets_BatchUpdateValuesRequest_ValueInputOption_Raw
            
            request.data = headers.compactMap { header in
                let valueRange = GTLRSheets_ValueRange()
                valueRange.majorDimension = kGTLRSheets_ValueRange_MajorDimension_Rows
                valueRange.range = "\(header.sheet)!A1"
                valueRange.values = [header.names]
                return valueRange
            }
            
            let query = GTLRSheetsQuery_SpreadsheetsValuesBatchUpdate.query(withObject: request, spreadsheetId:id)
            let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateValuesResponse>(service:service, scopes:scopes)
            _ = try await Google.execute(query, fetcher: fetcher)
            
        } catch {
            throw error
        }
    }
}


//MARK: - Get
extension Sheets {
    func getSpreadsheet(_ spreadsheetID:String, ranges:[String]? = nil, fields:String? = nil) async throws -> GTLRSheets_Spreadsheet {
        do {
            let query = GTLRSheetsQuery_SpreadsheetsGet.query(withSpreadsheetId: spreadsheetID)
            //https://developers.google.com/workspace/sheets/api/guides/field-masks
            if let ranges {
                let title    = GTLRSheets_Spreadsheet.Field.sheetTitle.rawValue
                let chipRuns = GTLRSheets_Spreadsheet.Field.chipRuns.rawValue
                query.fields = fields ?? "sheets(\(title)\(chipRuns))"
                query.ranges = ranges
//                query.includeGridData = true //can be SLOW - but will return all data in the spreadsheet, including chipRuns
            }
            let fetcher = Google_Fetcher<GTLRSheets_Spreadsheet>(service:service, scopes:scopes)
            
            let spreadsheet = try await Google.execute(query, fetcher: fetcher)

            return spreadsheet
        } catch {
            throw error
        }
    }
    func getValues(_ spreadsheetID:String, ranges:[String], removeHeader:Bool = true) async throws -> [(range:String, values:[[String]])] {
        let query = GTLRSheetsQuery_SpreadsheetsValuesBatchGet.query(withSpreadsheetId: spreadsheetID)
        query.majorDimension = kGTLRSheets_ValueRange_MajorDimension_Rows
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
                        allResults.append((range, removeHeader ? Array(values.dropFirst()) : values ))
                    }
                }
                return  allResults
            }
            throw Google_Error.driveCallSuceededButReturnTypeDoesNotMatch
        } catch {
            throw error
        }
    }
    func getRowNumbers(spreadsheetID: String, sheetName: String, columnLetter: String = "A", uniqueIds: [String]) async throws -> [Int]? {
        do {
            let result = try await getValues(spreadsheetID, ranges: ["\(sheetName)!\(columnLetter):\(columnLetter)"], removeHeader: false)
            guard let values   = result.first?.values as? [[String]] else { return nil }
            
            var foundIndexes: [Int] = []
            for (index, value) in values.enumerated() {
                if let rowID = value.first, uniqueIds.contains(rowID) {
                    foundIndexes.append(index)
                }
            }
            guard uniqueIds.count == foundIndexes.count else { return nil }
            return foundIndexes

        } catch {
            throw error
        }
    }
    func getRowNumber(spreadsheetID: String, sheetName: String, columnLetter: String = "A", uniqueId: String) async throws -> Int? {
        do {
            return try await getRowNumbers(spreadsheetID: spreadsheetID, sheetName: sheetName, columnLetter: columnLetter, uniqueIds: [uniqueId])?.first
        } catch {
            throw error
        }
    }
    func getRowNumbers(spreadsheetID:String, sheetRows:[any SheetRow], columnLetter:String = "A") async throws -> [(any SheetRow, Int)]? {
        let sheetInts:Set<Int> = Set(sheetRows.compactMap(\.sheetID))
        let sheets             = sheetInts.compactMap({Case.Sheet.sheet($0)})
        let ranges             = sheets.compactMap({"\($0.rawValue)!\(columnLetter):\(columnLetter)"})
        
        do {
            let rangeValues = try await getValues(spreadsheetID, ranges: ranges, removeHeader: false)
            var foundIndexes: [(any SheetRow, Int)] = []
            for sheetRow in sheetRows {
                var found = false
                for rangeValue in rangeValues {
                    if let sheetRowID = sheetRow.id as? String, let rowIndex = rangeValue.values.firstIndex(where: {$0.first == sheetRowID}) {
                        foundIndexes.append((sheetRow, rowIndex) )
                        found = true
                        break
                    }
                }
                if !found { return nil }
            }
            return foundIndexes.count == sheetRows.count ? foundIndexes : nil
        } catch {
            throw error
        }
    }

}


//MARK: - Append
extension Sheets {
    func append(_ sheetRows:[any SheetRow], to spreadsheetID:String,) async throws {
        do {
            let update = GTLRSheets_BatchUpdateSpreadsheetRequest()
            var requests = [GTLRSheets_Request]()
            
            let sheetIDs = sheetRows.compactMap { $0.sheetID }.unique()
            for sheetID in sheetIDs {
                let rows = sheetRows.filter { $0.sheetID == sheetID}

                let request = GTLRSheets_Request()
                let append  = GTLRSheets_AppendCellsRequest()
                append.fields = "*"
                append.sheetId = NSNumber(value: sheetID)
                append.rows = rows.compactMap(\.rowData)
                request.appendCells = append
                
                requests.append(request)
            }
            update.requests = requests

            let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: update, spreadsheetId:spreadsheetID)
            let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateSpreadsheetResponse>(service:service, scopes:scopes)

            _ = try await Google.execute(query, fetcher: fetcher)
            
        } catch {
            print("Error: \(error.localizedDescription)")
            throw error
        }
    }
    func appendStringRows(_ sheetRows:[any SheetStringsRow], to spreadsheetID:String,) async throws {
        do {

            let update = GTLRSheets_BatchUpdateSpreadsheetRequest()
            let uniqueIDs = sheetRows.compactMap { $0.sheetID }.unique()
            var requests : [GTLRSheets_Request] = []
            
            for uniqueID in uniqueIDs {
                let request = GTLRSheets_Request()
                let append  = GTLRSheets_AppendCellsRequest()
                append.fields = "userEnteredValue"
                append.sheetId = NSNumber(value:uniqueID)
                
                let rows = sheetRows.filter { $0.sheetID == uniqueID}
                let rowData = GTLRSheets_RowData()
                for row in rows {
                    let rowCellData : [GTLRSheets_CellData] = row.strings.compactMap { string in
                        let cellData = GTLRSheets_CellData()
                        let userData = GTLRSheets_ExtendedValue()
                        userData.stringValue = string
                        cellData.userEnteredValue = userData
                        return cellData
                    }
                    rowData.values = rowCellData
                }
                append.rows = [rowData]
                request.appendCells = append
                requests.append(request)
            }
        
            update.requests = requests

            
            let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: update, spreadsheetId: spreadsheetID)
            let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateSpreadsheetResponse>(service:service, scopes:scopes)

           _ = try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
}


//MARK: - Update
extension Sheets {
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
    func update(spreadsheetID:String, sheetRowPairs:[(any SheetRow, Int)]) async throws -> Bool {
        do {
            let batch    = GTLRSheets_BatchUpdateSpreadsheetRequest()
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
            batch.requests = requests
            let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: batch, spreadsheetId: spreadsheetID)
            let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateSpreadsheetResponse>(service:service, scopes:scopes)
            _ = try await Google.execute(query, fetcher: fetcher)
            return true
        } catch {
            throw error
        }
    }
    func update(spreadsheetID:String, sheetRows:[any SheetRow] ) async throws  {
        do {
            guard sheetRows.count > 0 else { throw NSError.quick("No rows to update.") }
            guard let sheetRowPairs = try await getRowNumbers(spreadsheetID: spreadsheetID, sheetRows: sheetRows) else { throw NSError.quick("Not all items found in spreadsheet.") }
            _ = try await update(spreadsheetID: spreadsheetID, sheetRowPairs: sheetRowPairs)
        } catch {
            throw error
        }
    }
}


//MARK: - Delete
extension Sheets {
    
}
