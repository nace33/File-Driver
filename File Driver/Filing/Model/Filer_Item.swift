//
//  Filer_Item.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/23/25.
//

import Foundation
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

@Observable
final class Filer_Item : Identifiable, Hashable {
    static func == (lhs: Filer_Item, rhs: Filer_Item) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    
    let id          : String
    var file        : GTLRDrive_File?
    let remoteURL   : URL?
    var localURL    : URL?
    var filename    : String
    var category    : Category
    var emailThread : EmailThread?
    var status      : Status
    
    
    enum Category {
        case driveFile, remoteURL, remotePDFURL, localURL
    }
    enum Status {
        case notReadyToFile, readyToFile, filed, error
    }
    
    
    var canFileLater : Bool {
        category == .localURL && status == .readyToFile
    }
    
    init(file:GTLRDrive_File) {
        self.id          = file.id
        self.file        = file
        self.category    = .driveFile
        self.status      = .readyToFile
        self.filename    = file.titleWithoutExtension
        self.remoteURL   = nil
        self.localURL    = nil
        self.emailThread =  EmailThread(appProperties: file.appProperties)
    }
    
    init(url:URL, filename:String, category:Category) {
        self.id     = UUID().uuidString
        self.file   = nil
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
