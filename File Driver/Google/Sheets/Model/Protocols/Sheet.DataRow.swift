
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
protocol SheetRow : Identifiable {
    var sheetID : Int                    { get }
    init?(rowData:GTLRSheets_RowData)
    var rowData : GTLRSheets_RowData     { get }
    var cellData : [GTLRSheets_CellData] { get }
}

extension SheetRow {
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
extension SheetRow {
    var rowData: GTLRSheets_RowData {
        let rowData = GTLRSheets_RowData()
        rowData.values = cellData
        return rowData
    }
}


public extension Array where Element: Equatable {
    func next(_ element: Element) -> Element? {
        guard let index = firstIndex(of: element),
                index + 1 < self.count else { return nil }
        return self[index + 1]
    }
}

extension Sheets {
    struct FileChipRun : Decodable,Hashable  {
        var chipRuns         : [FileChip]
        var formattedValue   : String
 
        var cellData : GTLRSheets_CellData {
            let cellData = GTLRSheets_CellData()
            
            let userValue = GTLRSheets_ExtendedValue()
            userValue.stringValue = formattedValue
            cellData.userEnteredValue = userValue
            
            cellData.setJSONValue(chipRuns.compactMap({$0.fileChipDictionary}), forKey: "chipRuns")
            return cellData
        }
        var ids : [String] {
            chipRuns.compactMap { id($0)}
        }
        var firstID : String? {
            firstURIChip?.id
        }
        var firstTitle : String? {
            if let chip = firstURIChip {
                return title(chip)
            }
            return nil
        }
        var firstURIChip : FileChip? {
            chipRuns.first(where: {$0.uri != nil})
        }
        func id(_ chip:FileChip) -> String? {
            chipRuns.first(where: {$0.uri == chip.uri})?.id
        }
        func title(_ chip:FileChip) -> String? {
            //The json from google can contain:
            //None, 1, or more startIndexes
            //where needed to build the title for the chip
           
            //if no URI - return nil
            guard chip.uri != nil else { return nil }
            
            //if no startIndexes provided by Google, return entire string
            let startIndexes = chipRuns.compactMap(\.startIndex)
            guard startIndexes.count > 0 else { return formattedValue }
            
      
            if let startIndex = chip.startIndex {
                //if chip has a startIndex, that is the begining of the title for the chip
                //the end is either the beginning of the next chip or the end of the string
                let start = formattedValue.index(formattedValue.startIndex, offsetBy: startIndex)
                let nextIndex = startIndexes.next(startIndex) ?? formattedValue.count
                let end = formattedValue.index(start, offsetBy: nextIndex - startIndex)
                let sub = formattedValue[start..<end]
                return String(sub)
            } else {
                //if the chip has no start index, the title begins at the begining of the string
                //the end of the title is either the first startIndex or the end of the string
                let start     = formattedValue.startIndex
                let nextIndex = startIndexes.first ?? formattedValue.count
                let end = formattedValue.index(start, offsetBy: nextIndex)
                let sub = formattedValue[start..<end]
                return String(sub)
            }
        }

        //get all strings in the chipRuns
        //combined they equal formattedString
        var stringSlices : [String] {
            let string = formattedValue
            var indexes = chipRuns.compactMap(\.startIndex)
            indexes.append(string.count)
            var strings : [String] = []
            print("\n\n\(string)\nIndexes: \(indexes)")
            print("Chip Runs: \(chipRuns.count)")
            for (index, element) in chipRuns.enumerated() {
                if element.uri != nil {
                    print("\tID at \(index)")
                }
            }
            for (index, sliceIndex) in  indexes.enumerated() {
                let priorSlice = index == 0 ? 0 :  indexes[index - 1]
                let start = string.index(string.startIndex, offsetBy: priorSlice)
                let end   = string.index(start, offsetBy: sliceIndex - priorSlice)
                let sub = string[start..<end]
//                if sub.count > 0 {
                    strings.append(String(sub))
                    print("\t\t\(sub)")
//                }
            }
            return strings
        }
        
        
    }
    
    struct FileChip    : Decodable, Hashable {
        let uri        : String?
        let mimeType   : String?
        let startIndex : Int?
        static func createDriveURI(_ fileID:String, mimeType:String?) -> String {
            if let mimeType, mimeType == GTLRDrive_File.MimeType.folder.rawValue {
                return "https://drive.google.com/drive/folders/\(fileID)"
            }
            return "https://drive.google.com/file/d/\(fileID)"
        }
        init(fileID:String, mimeType:String?, startIndex:Int? = nil) {
            self.uri = FileChip.createDriveURI(fileID, mimeType: mimeType)
            self.mimeType = mimeType
            self.startIndex = startIndex
        }
        public init(from decoder: Decoder) throws {
            do {
                let container                 = try decoder.container(keyedBy: JSONCodingKeys.self)
                let dictionary : [String:Any] = JSONCodingKeys.decode(fromObject: container)
                startIndex = dictionary["startIndex"] as? Int
                
                let chip       : [String:Any] = dictionary["chip"] as? [String : Any] ?? [:]
                let richLink   : [String:Any] = chip["richLinkProperties"] as? [String:Any] ?? [:]
                
                uri      = richLink["uri"] as? String
                mimeType = richLink["mimeType"] as? String
                
            } catch {
                throw error
            }
        }
        var fileChipDictionary : [String:Any] {
            if let startIndex, let mimeType  {
                return [
                    "startIndex": startIndex,
                    "chip":["richLinkProperties":["uri":uri, "mimeType":mimeType]]
                ]
            } else if let startIndex {
                return [
                    "startIndex": startIndex,
                    "chip":["richLinkProperties":["uri":uri]]
                ]
            } else if let mimeType {
                return [
                    "chip":["richLinkProperties":["uri":uri, "mimeType":mimeType]]
                ]
            } else {
                return [
                    "chip":["richLinkProperties":["uri":uri]]
                ]
            }
        }
        
        var id : String? {
            (uri as? NSString)?.lastPathComponent
        }
    }
}


//MARK: - File Chips
extension Sheets.FileChipRun {
    init(fileIDs:[String], mimeType:String?) {
        var chipRuns : [Sheets.FileChip] = []
        var startIndex = 0
        var string = ""
        for id in fileIDs {
            let run = Sheets.FileChip(fileID: id, mimeType:mimeType, startIndex: startIndex)
            startIndex += 1
            string += "@"
            chipRuns.append(run)
        }
        self.chipRuns = chipRuns
        formattedValue = string
    }
    init(files:[GTLRDrive_File]) {
        var chipRuns : [Sheets.FileChip] = []
        var startIndex = 0
        var string = ""
        for file in files {
            let run = Sheets.FileChip(fileID: file.id, mimeType: file.mimeType, startIndex: startIndex)
            startIndex += 1
            string += "@"
            chipRuns.append(run)
        }
        self.chipRuns = chipRuns
        formattedValue = string
    }
}

fileprivate
struct JSONCodingKeys: CodingKey {
    var stringValue: String
    init(stringValue: String) {
    self.stringValue = stringValue
  }
    var intValue: Int?
    init?(intValue: Int) {
    self.init(stringValue: "\(intValue)")
    self.intValue = intValue
  }
    static func decode(fromObject container: KeyedDecodingContainer<JSONCodingKeys>) -> [String: Any] {
        var result: [String: Any] = [:]

        for key in container.allKeys {
            if let val = try? container.decode(Int.self, forKey: key) { result[key.stringValue] = val }
            else if let val = try? container.decode(Double.self, forKey: key) { result[key.stringValue] = val }
            else if let val = try? container.decode(String.self, forKey: key) { result[key.stringValue] = val }
            else if let val = try? container.decode(Bool.self, forKey: key) { result[key.stringValue] = val }
            else if let nestedContainer = try? container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key) {
                result[key.stringValue] = decode(fromObject: nestedContainer)
            } else if (try? container.decodeNil(forKey: key)) == true  {
                result.updateValue(Optional<Any>(nil) as Any, forKey: key.stringValue)
            }
        }
        return result
    }
}
