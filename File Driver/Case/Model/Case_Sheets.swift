//
//  CaseType.swift
//  FD_Filing
//
//  Created by Jimmy Nasser on 4/16/25.
//


//MARK: ENUMS
extension Case {
    enum Sheet : String, CaseIterable, Identifiable {
        var id : String { self.rawValue }
        var title : String { rawValue.capitalized }
        init?(sheetRange:String) { //sheetRange is the format: "Folders!A1:C1005
            guard let sheetName = sheetRange.components(separatedBy: "!").first else { return nil }
            self.init(rawValue: sheetName.lowercased())
        }
        case folders
        case contacts
        case tags
        case filings
    }
    
    //LOAD
    func load(_ sheets:[Sheet]) async {
        do {
            let results = try await Google_Sheets.shared.getValues(spreadsheetID: id, ranges: sheets.map(\.rawValue))
            for result in results {
                if let sheet = Sheet(sheetRange: result.range) {
                    switch sheet {
                    case .folders:
                        load(folders: result.values)
                    case .contacts:
                        load(contacts: result.values)
                    default:
                        print("Need to Load \(sheet.title)")
                    }
                } else {
                    print("Unable to locate sheet for: \(result.range). Check ot make sure rangeName is one word and has a matching Sheet enumer in the extension.")
                }
            }
        } catch {
            print("\(#function) Error: \(error.localizedDescription)")
        }
    }
}
