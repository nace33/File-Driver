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


//MARK: - Create
extension Sheets {
    ///this creates the sheet in user's drive, no option to pick where the sheet is created.
    func create(_ spreadsheet:GTLRSheets_Spreadsheet) async throws -> GTLRSheets_Spreadsheet {
        do {
            let fetcher = Google_Fetcher<GTLRSheets_Spreadsheet>(service:service, scopes:scopes)
            let query   = GTLRSheetsQuery_SpreadsheetsCreate.query(withObject: spreadsheet)
            return try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    
    ///this is used immediately after a sheet is created in Drive.  try await Drive.shared.create(fileType: .sheet, name:"Sample", parentID: "DestiniationID")
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
    func getRowNumbers(spreadsheetID:String, sheetRows:[any GoogleSheetRow], columnLetter:String = "A") async throws -> [(any GoogleSheetRow, Int)]? {
        
        let ranges = sheetRows.compactMap({"\($0.sheetName)!\(columnLetter):\(columnLetter)"})
        
        do {
            let rangeValues = try await getValues(spreadsheetID, ranges: ranges, removeHeader: false)
            var foundIndexes: [(any GoogleSheetRow, Int)] = []
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
            print(#function + " Error: \(error.localizedDescription)")
            throw error
        }
    }

}


//MARK: - Formatting
extension Sheets {
    func addHeaders(_ headers:[Sheets.Header], in spreadsheetID:String) async throws {
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
            
            let query = GTLRSheetsQuery_SpreadsheetsValuesBatchUpdate.query(withObject: request, spreadsheetId:spreadsheetID)
            let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateValuesResponse>(service:service, scopes:scopes)
            _ = try await Google.execute(query, fetcher: fetcher)
            
        } catch {
            throw error
        }
    }
    func addNamedRanges(_ namedRanges:[GTLRSheets_NamedRange], in spreadsheetID:String) async throws {
        let batch              = GTLRSheets_BatchUpdateSpreadsheetRequest()
        batch.requests = requests(for:namedRanges)
        do {
            let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: batch, spreadsheetId:spreadsheetID)
            let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateValuesResponse>(service:service, scopes:scopes)
            _ = try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
    }
    func format(wrap:WrapStrategy? = nil, vertical:Vertical? = nil, horizontal:Horizontal? = nil, sheets:[Int], in spreadsheetID:String) async throws {
        guard sheets.count > 0 else { throw NSError.quick("No Sheets Specified")}
        guard wrap != nil || vertical != nil || horizontal != nil else { throw NSError.quick("No Alignment Specified") }
        
        let batch = GTLRSheets_BatchUpdateSpreadsheetRequest()

        batch.requests = requests(wrap: wrap, vertical: vertical, horizontal: horizontal, sheets: sheets)
   
        do {
            let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: batch, spreadsheetId:spreadsheetID)
            let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateSpreadsheetResponse>(service:service, scopes:scopes)
            
            _ = try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
        
    }
}


//MARK: - Append
extension Sheets {
    func append(_ sheetRows:[any GoogleSheetRow], to spreadsheetID:String,) async throws {
        do {
            let update = GTLRSheets_BatchUpdateSpreadsheetRequest()
        
            update.requests = requests(append:sheetRows)

            let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: update, spreadsheetId:spreadsheetID)
            let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateSpreadsheetResponse>(service:service, scopes:scopes)

            _ = try await Google.execute(query, fetcher: fetcher)
            
        } catch {
            print("Error: \(error.localizedDescription)")
            throw error
        }
    }
}


//MARK: - Update
extension Sheets {
    func update(spreadsheetID:String, sheetRowPairs:[(any GoogleSheetRow, Int)]) async throws -> Bool {
        do {
            let batch    = GTLRSheets_BatchUpdateSpreadsheetRequest()
            batch.requests = requests(update:sheetRowPairs)
            let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: batch, spreadsheetId: spreadsheetID)
            let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateSpreadsheetResponse>(service:service, scopes:scopes)
            _ = try await Google.execute(query, fetcher: fetcher)
            return true
        } catch {
            throw error
        }
    }
    func update(spreadsheetID:String, sheetRows:[any GoogleSheetRow] ) async throws  {
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


//MARK: - Find & Replace
extension Sheets {
    ///Does NOT find a value in one column and replace in another column
    ///only replaces the value found
    func find(_ string:String, replace:String, sheetID:Int? = nil, in spreadsheetID:String) async throws {
       
        let batch = GTLRSheets_BatchUpdateSpreadsheetRequest()
     
        batch.requests = requests(find: string, replace: replace, sheetID: sheetID)
        
        do {
            let query = GTLRSheetsQuery_SpreadsheetsBatchUpdate.query(withObject: batch, spreadsheetId: spreadsheetID)
            let fetcher = Google_Fetcher<GTLRSheets_BatchUpdateSpreadsheetResponse>(service:service, scopes:scopes)

           _ = try await Google.execute(query, fetcher: fetcher)
        } catch {
            throw error
        }
      
    }
}
