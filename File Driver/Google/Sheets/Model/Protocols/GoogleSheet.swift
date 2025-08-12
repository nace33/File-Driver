//
//  Sheet.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/12/25.
//

import Foundation
import GoogleAPIClientForREST_Sheets



protocol GoogleSheet :  CaseIterable, Equatable {
    var title       : String                   { get }
    var rawValue    : String                   { get }
    var intValue    : Int                      { get }
    var headerRow   : Sheets.Header            { get }
    var columns     : [any GoogleSheetColumn]  { get }
    var namedRanges : [GTLRSheets_NamedRange]  { get }
}

extension GoogleSheet {
    //overrrides
    var intValue : Int { Self.allCases.firstIndex(of: self)! as! Int }
    var headerRow : Sheets.Header {
        Sheets.Header(sheet: rawValue, names: columns.compactMap(\.rawValue))
    }
  
    
    //Helpers
    static func sheet(_ intValue:Int) -> (any GoogleSheet)? {
        guard (0..<Self.allCases.count).contains(intValue) else { return nil }
        return Self.allCases.first(where: {$0.intValue == intValue})!
    }
    static func namedRange(_ title:String, sheet:Self, column:any GoogleSheetColumn) -> GTLRSheets_NamedRange? {
        guard let columnIndex = column.index(in: sheet) else { return nil }
        let namedRange = GTLRSheets_NamedRange()
        namedRange.name         = title
        namedRange.namedRangeId = title
        let range = GTLRSheets_GridRange()
        range.sheetId = NSNumber(value: sheet.intValue)
        range.startColumnIndex = NSNumber(value: columnIndex)
        range.endColumnIndex   = NSNumber(value: columnIndex + 1)
        range.startRowIndex    = NSNumber(value: 1)
        namedRange.range       = range
        return namedRange
    }
    
    //GTLR
    var gtlrSheet : GTLRSheets_Sheet {
        let newSheet         = GTLRSheets_Sheet()
        
        //Set Sheet properties
        let properties       = GTLRSheets_SheetProperties()
        properties.index     = NSNumber(value: self.intValue)
        properties.sheetId   = NSNumber(value: self.intValue)
        properties.sheetType = kGTLRSheets_SheetProperties_SheetType_Grid
        properties.title     = self.title
        
        //set column and row dimensions
        properties.gridProperties = gtlrSheetGridProperties
        
        //add to Spreadsheet
        newSheet.properties = properties
        return newSheet
    }
    var gtlrSheetGridProperties : GTLRSheets_GridProperties {
        let columns          = self.columns
        let grid             = GTLRSheets_GridProperties()
        grid.columnCount     = NSNumber(value: columns.count)
        grid.frozenRowCount  = NSNumber(value: 1)
        grid.rowCount        = NSNumber(value: 1000)
        return grid
    }
    
    //This is not currently in use because API only allows spreadsheets to be created in user's drive
    //Use Drive to create a spreadsheet file in a desired folder/shared drive.
    static func newGtlrSpreadsheet(title:String) -> GTLRSheets_Spreadsheet {
        let newSpreadsheet = GTLRSheets_Spreadsheet()
     
        let spreadsheetProperties = GTLRSheets_SpreadsheetProperties()
        spreadsheetProperties.title = title
        newSpreadsheet.properties = spreadsheetProperties
        
        
        newSpreadsheet.sheets      = Self.allCases.compactMap { $0.gtlrSheet   }
        newSpreadsheet.namedRanges = Self.allCases.flatMap    { $0.namedRanges }

        return newSpreadsheet
    }
}
