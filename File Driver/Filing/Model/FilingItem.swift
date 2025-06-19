//
//  FilingItem.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//
import Foundation
import GoogleAPIClientForREST_Drive

struct FilingItem : Identifiable {
    var id       : String = UUID().uuidString
    let localURL : URL?
    var fileURL  : URL { localURL ?? file?.url ?? URL(string:"about:blank")!}
    var file     : GTLRDrive_File?
    var name     : String { localURL?.deletingPathExtension().lastPathComponent ?? file?.name ?? "No Filename"}
    var status   : Status
    var progress : Float = 0
    var error    : Filing_Error?
    var dateAdded: Date
 
    
    //guaranteed to either have a localFileURL or a google Drive ID
    init?(fileURL:URL) {
        guard fileURL.isFileURL else { return nil }
        self.localURL = fileURL
        status = .uploading
        self.dateAdded = Date()
    }
    init(file:GTLRDrive_File) {
        self.localURL = nil
        self.file = file
        status = .readyToFile
        self.dateAdded = file.modifiedTime?.date ?? Date()
    }
}

//MARK: Icon
extension FilingItem {
    var imageString : String {
        file?.mime.title ?? "Unknown"
    }
}

//MARK: Status
extension FilingItem {
    enum Status : String, CaseIterable, Identifiable {
        var id : String { rawValue }
        
        case  cancelled, failed, uploading, readyToFile
        
        var title : String {
            rawValue.camelCaseToWords()
        }

        var intValue    : Int {
            Status.allCases.firstIndex(of: self) ?? -1
        }
    }
    var isUploading : Bool { status == .uploading }
}
