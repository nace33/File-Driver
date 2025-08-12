//
//  Contact.File.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/11/25.
//

import Foundation
import GoogleAPIClientForREST_Drive
import UniformTypeIdentifiers

public
extension Contact {
    
    struct File : Identifiable, Hashable{
        public let id   : String
        var dateID      : String
        var fileID      : String
        var category    : String
        var filename    : String
        var mimeType    : String
        var fileSize    : String
        var note        : String
        
        
        init(id: String, dateID:String, fileID: String, category: String, filename: String, mimeType: String, fileSize: String, note: String) {
            self.id = id
            self.dateID = dateID
            self.fileID = fileID
            self.category = category
            self.filename = filename
            self.mimeType = mimeType
            self.fileSize = fileSize
            self.note = note
        }
        static func new(url:URL) -> File {
            let id = UUID().uuidString
            let dateID = Date.idString
            let fileID = ""
            let category = ""
            let filename = url.deletingPathExtension().lastPathComponent
            let mimeType = url.fileType
            let fileSize = url.sizeString
            let note     = ""
            return File(id: id, dateID:dateID, fileID: fileID, category: category, filename: filename, mimeType: mimeType, fileSize: fileSize, note: note)
        }
        var title : String { filename.isEmpty ? "No filename" : filename }
        
        enum Status : String { case idle, removing, trashing}
        var status : Status = .idle
        
        var imageString : String {
            GTLRDrive_File.MimeType(rawValue: mimeType)?.title ?? "JSON"
        }
    }
}

public extension Contact.File {
    static var urlTypes : [UTType] {[
        .audio, .video, .image, .pdf, .text, .movie, .emailMessage, .message, .spreadsheet, .presentation, .package, .script, .fileURL, UTType(filenameExtension: "pages")!
    ]}
    struct LocalURL : Identifiable {
        public let id = UUID()
        let url : URL
    }
}



import GoogleAPIClientForREST_Sheets
extension Contact.File  : GoogleSheetRow {
    var sheetID: Int { Contact.Sheet.files.intValue }
    var sheetName : String { Contact.Sheet.files.rawValue}

    init?(rowData: GTLRSheets_RowData) {
        guard let values = rowData.values else { return nil }
        guard values.count  >= 7 else { return nil }
        guard let id         = values[0].formattedValue else { return nil }
        guard let dateID     = values[1].formattedValue else { return nil }
        guard let fileID     = values[2].formattedValue else { return nil }
        guard let category   = values[3].formattedValue else { return nil }
        guard let filename   = values[4].formattedValue else { return nil }
        guard let mimeType   = values[5].formattedValue else { return nil }
        guard let fileSize   = values[6].formattedValue else { return nil }
        
        //Optionals
        let note         = values.count >= 7 ? values[6].formattedValue ?? "" : ""

        self.id         = id
        self.dateID     = dateID
        self.fileID     = fileID
        self.category   = category
        self.filename   = filename
        self.mimeType   = mimeType
        self.fileSize   = fileSize
        self.note       = note
        
    }

    
    var cellData: [GTLRSheets_CellData] {[
        Self.stringData(id),
        Self.stringData(dateID),
        Self.stringData(fileID),
        Self.stringData(category),
        Self.stringData(filename),
        Self.stringData(mimeType),
        Self.stringData(fileSize),
        Self.stringData(note)
    ]}
}
