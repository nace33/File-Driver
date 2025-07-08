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
        var fileID      : String
        var category    : String
        var filename    : String
        var mimeType    : String
        var fileSize    : String
        var note        : String
        
        var strings     : [String] { [id, fileID, category, filename, mimeType, fileSize, note] }
        
        init(id: String, fileID: String, category: String, filename: String, mimeType: String, fileSize: String, note: String) {
            self.id = id
            self.fileID = fileID
            self.category = category
            self.filename = filename
            self.mimeType = mimeType
            self.fileSize = fileSize
            self.note = note
        }
        static func new(url:URL) -> File {
            let id = UUID().uuidString
            let fileID = ""
            let category = ""
            let filename = url.deletingPathExtension().lastPathComponent
            let mimeType = url.fileType
            let fileSize = url.sizeString
            let note     = ""
            return File(id: id, fileID: fileID, category: category, filename: filename, mimeType: mimeType, fileSize: fileSize, note: note)
        }
        var title : String { filename.isEmpty ? "No filename" : filename }
        
        enum Status : String { case idle, removing, deleting}
        var status : Status = .idle
        
        var imageString : String {
            GTLRDrive_File.MimeType(rawValue: mimeType)?.title ?? "JSON"
        }
    }
}

public extension Contact.File {
    init?(row:[String]) {
        let count = row.count
        guard count >= 1 else { return nil }
        self.id         = row[0]
        self.fileID     = count >= 2 ? row[1] : ""
        self.category   = count >= 3 ? row[2] : ""
        self.filename   = count >= 4 ? row[3] : ""
        self.mimeType   = count >= 5 ? row[4] : ""
        self.fileSize   = count >= 6 ? row[5] : ""
        self.note       = count >= 7 ? row[6] : ""

    }
    
    static var urlTypes : [UTType] {[
        .audio, .video, .image, .pdf, .text, .movie, .emailMessage, .message, .spreadsheet, .presentation, .package, .script, .fileURL, UTType(filenameExtension: "pages")!
    ]}
    struct LocalURL : Identifiable {
        public let id = UUID()
        let url : URL
    }
}



