//
//  Filer_Item.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/23/25.
//

import Foundation
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

//for use with presenting sheets, since the item must conform to identifiable
//See Case.TrackersView -> File upload
struct FilerSheetItem : Identifiable {
    let id = UUID()
    let urls : [URL]
    var items : [Filer_Item] {
       urls.compactMap { Filer_Item(url: $0, filename: $0.deletingPathExtension().lastPathComponent, category: .localURL) }
    }
}

@Observable
final class Filer_Item : Identifiable, Hashable {
    static func == (lhs: Filer_Item, rhs: Filer_Item) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    
    let id          : String
    let fileAction  : Action
    var file        : GTLRDrive_File?
    let remoteURL   : URL?
    var localURL    : URL?
    var filename    : String
    var category    : Category
    var emailThread : EmailThread?
    var status      : Status
    var filedToCase : Case?
    
    enum Category {
        case driveFile, remoteURL, remotePDFURL, localURL
    }
    enum Status {
        case notReadyToFile, readyToFile, filed, error
    }
    enum Action {
        case move, copy
    }
    
    var canFileLater : Bool {
        category == .localURL && status == .readyToFile
    }
    
    init(file:GTLRDrive_File, action:Action = .move) {
        self.id          = file.id
        self.file        = file
        self.category    = .driveFile
        self.status      = .readyToFile
        self.filename    = file.titleWithoutExtension
        self.remoteURL   = nil
        self.localURL    = nil
        self.emailThread =  EmailThread(appProperties: file.appProperties)
        self.fileAction  = action
    }
    
    init(url:URL, filename:String, category:Category) {
        self.id              = UUID().uuidString
        self.file            = nil
        self.fileAction      = .move
        
        if category == .localURL {
            self.localURL    = url
            self.remoteURL   = nil
            self.status      = .readyToFile
            self.filename    = url.deletingPathExtension().lastPathComponent
            self.emailThread = url.emailThread
        } else {
            self.localURL    = nil
            self.remoteURL   = url
            self.status      = .notReadyToFile
            self.filename    = filename
            self.emailThread = nil
        }
        self.category = category
    }
    
    func resetFilename() {
        switch category {
        case .driveFile:
            if let file {
                filename = file.titleWithoutExtension
            }
        case .remoteURL, .remotePDFURL:
            break
        case .localURL:
            if let localURL {
                filename = localURL.deletingPathExtension().lastPathComponent
            }
        }
    }

    var lowercasedSearchStrings:Set<String> {
        var strings:Set<String> = []
        if let thread = emailThread {
            strings.formUnion(thread.lowercasedStrings)
        }
        strings.insert(filename.lowercased())
        return strings
    }
    
    var lowercasedSearchWords:Set<String> {
        var strings:Set<String> = []
        if let thread = emailThread {
            strings.formUnion(thread.lowercasedSearchWords)
        }
        strings.formUnion(filename.lowerCasedWordsSet)
        return strings
    }
 }
