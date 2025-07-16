//
//  FileToCase_Item.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/9/25.
//

import Foundation
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

@Observable
final class FileToCase_Item : Identifiable, Hashable {
    static func == (lhs: FileToCase_Item, rhs: FileToCase_Item) -> Bool { lhs.file.id == rhs.file.id }
    func hash(into hasher: inout Hasher) { hasher.combine(file.id) }

    let id              : String
    var filename        : String
    var file            : GTLRDrive_File

    init(_ file:GTLRDrive_File) {
        self.id = UUID().uuidString
        self.filename = file.titleWithoutExtension
        self.file = file
    }
    var suggestionData : Suggestions.Data { .init(self) }
    func resetFilename() {
        filename = file.titleWithoutExtension
    }
    var emailThread : EmailThread? {
        EmailThread(appProperties: file.appProperties)
    }
}

/*
@Observable
final class FileToCase_URLItem : Identifiable, Hashable {
    static func == (lhs: FileToCase_URLItem, rhs: FileToCase_URLItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id          : String
    var filename    : String
    var url         : URL
    var type        : URLType
    var status      : Status
    var pdfGmailThread  : EmailThread?
    enum URLType {
        case localURL, downloadURL, printToPDF
    }
    enum Status {
        case notReadyToFile, readyToFile, filed, error
    }
    
    init(_ url:URL, title:String?, type:URLType) {
        self.id = UUID().uuidString
        self.url = url
        self.filename = title ?? url.deletingLastPathComponent().lastPathComponent
        self.type = type
        self.status = (type == .localURL) ? .readyToFile : .notReadyToFile
        self.pdfGmailThread = nil
    }
}
*/

@Observable
final class FileToCase_URLItem : Identifiable, Hashable {
    static func == (lhs: FileToCase_URLItem, rhs: FileToCase_URLItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    
    let id          : String
    let file        : GTLRDrive_File?
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
    
    var suggestionData : Suggestions.Data {
        switch category {
        case .driveFile:
            Suggestions.Data(words: [], strings: [], contacts: [])
        case .remoteURL:
            Suggestions.Data(words: [], strings: [], contacts: [])
        case .remotePDFURL:
            Suggestions.Data(words: [], strings: [], contacts: [])
        case .localURL:
            Suggestions.Data(words: [], strings: [], contacts: [])
        }
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
    

 }
