//
//  Filing_Rename.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/26/25.
//

import SwiftUI
import BOF_SecretSauce
import PDFKit

//MARK: Enum
@MainActor
enum AutoFile_Rename : String, CaseIterable, Codable {
    case filename, dateAdded, filedate, emailDate, emailHost, emailSender, emailSubject, space, openParenthesis, closeParenthesis, underscore, dash, period, openSquare, closeSquare, hashTag, at, money, asterisk
    static var allFilename     : [Self] { [.filename, .dateAdded] }
    static var allEmail        : [Self] { [.emailDate, .emailHost, .emailSender, .emailSubject] }
    static var allPuntuation   : [Self] { [.space, .openParenthesis, .closeParenthesis, .underscore, .dash, .period, .openSquare, .closeSquare, .hashTag, .at, .money, .asterisk] }
    static var defaultFilename : [Self] { [.dateAdded, .space, .filename] }
    static var defaultEmail    : [Self] { [.emailDate,.space,.emailHost,.space,.openParenthesis,.emailSubject,.closeParenthesis]}
    
    static var variousFilenames : [[Self]] {[
        [.filename],
        [.hashTag, .period,.space, .filename],
        [.dateAdded, .space, .filename], //defaultFilename
        [.filedate, .space, .filename]
    ]}
    static var variousEmailNames : [[Self]] {[
        [.filename],
        [.emailSubject],
        [.hashTag, .period,.space, .filename],
        [.emailDate, .space, .emailHost],
        [.emailDate, .space, .emailSender],
        [.emailDate, .space, .emailSubject],
        [.emailDate,.space,.emailHost,.space,.openParenthesis,.emailSubject,.closeParenthesis], //default Email
        [.emailDate,.space,.emailSender,.space,.openParenthesis,.emailSubject,.closeParenthesis]
    ]}
    
    var title : String {
        switch self {
        case .filename:
            "Filename"
        case .dateAdded:
            "Date Added"
        case .filedate:
            "File Date"
        case .emailDate:
            "Date"
        case .emailHost:
            "Host"
        case .emailSender:
            "Sender"
        case .emailSubject:
            "Subject"
        case .space:
            "[space]"
        case .openParenthesis:
            "("
        case .closeParenthesis:
            ")"
        case .underscore:
            "_"
        case .dash:
            "-"
        case .period:
            "."
        case .openSquare:
            "["
        case .closeSquare:
            "]"
        case .hashTag:
            "#"
        case .at:
            "@"
        case .money:
            "$"
        case .asterisk:
            "*"
        }
    }
    var sampleString : String {
        switch self {
        case .filename:
            "Photo of Elephant"
        case .dateAdded:
            Date().yyyymmdd
        case .emailDate:
            Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date())?.yyyymmdd ?? Date().yyyymmdd
        case .emailHost:
            "nasserlaw"
        case .emailSender:
            "james@nasserlaw.com"
        case .emailSubject:
            "Amazon Order 43234"
        case .space:
            " "
        default:
            title
        }
    }
    
    
    func resultString(for url:URL, thread:EmailThread?) -> String? {
        switch self {
        case .filename:
            url.filename
        case .dateAdded:
            Date().yyyymmdd
        case .filedate:
            url.dateCreated.yyyymmdd
        case .emailDate:
            thread?.mostRecentHeader(in: thread?.fullHeaders ?? [])?.dateInfo?.date.yyyymmdd ?? ""
        case .emailHost:
            thread?.mostRecentHeader(in: thread?.fullHeaders ?? [])?.from?.emailHost ?? ""
        case .emailSender:
            thread?.mostRecentHeader(in: thread?.fullHeaders ?? [])?.from?.name ?? ""
        case .emailSubject:
            thread?.subject
        case .space:
            " "
        default :
            title
        }
    }
    
    static  func proposedFilename(for url:URL, thread:EmailThread?) -> String? {        
        let componentString : String
        if let thread, thread.headers.count > 0 {
            guard UserDefaults.standard.bool(forKey: BOF_Settings.Key.filingAutoRenameEmails.rawValue) else { return nil }
            componentString = BOF_Settings.Key.filingAutoRenameEmailComponents.rawValue
        } else {
            guard UserDefaults.standard.bool(forKey: BOF_Settings.Key.filingAutoRenameFiles.rawValue) else { return nil }
            componentString = BOF_Settings.Key.filingAutoRenameComponents.rawValue
        }
        
        guard var stringComponents = UserDefaults.standard.value(forKeyPath:componentString) as? String else { return nil}
        stringComponents = stringComponents.replacingOccurrences(of: "[", with: "")
        stringComponents = stringComponents.replacingOccurrences(of: "]", with: "")
        stringComponents = stringComponents.replacingOccurrences(of: "\"", with: "")
   
        let components = stringComponents.split(separator: ",")
        let renameComponents = components.compactMap { Self(rawValue: $0.trimmingCharacters(in: .whitespaces)) }


        var proposedFilename = renameComponents.compactMap { $0.resultString(for: url, thread: thread)}.joined()
        
        proposedFilename = FilerBlockText.removeBlockedWords(from: proposedFilename)
    
        return proposedFilename
    }

    static func generateFilename(for url:URL, thread:EmailThread? = nil) throws -> String? {
        let automaticallyRenameFiles  = UserDefaults.standard.bool(forKey: BOF_Settings.Key.filingAutoRenameFiles.rawValue)
        let automaticallyRenameEmails = UserDefaults.standard.bool(forKey: BOF_Settings.Key.filingAutoRenameEmails.rawValue)
        guard automaticallyRenameFiles || automaticallyRenameEmails else { return nil }
        guard url.isFileURL            else {  return nil }
        return  proposedFilename(for: url, thread:thread ?? url.emailThread)
    }
    
    static func autoRenameLocalFile(url:URL?, thread:EmailThread? = nil)  throws -> URL {
        
        do {
            guard let url else { throw NSError.quick("No URL was passed to the auto-renamer.")}
            _ = url.startAccessingSecurityScopedResource()
            
            guard let proposedFilename = try generateFilename(for: url, thread: thread) else { throw NSError.quick("Proposed filename unable to be generated.") }
            let directory = url.deletingLastPathComponent()

         
            let uniqueURL = FileManager.uniqueURL(for: proposedFilename, ext:url.pathExtension, at:directory)
            try FileManager.default.moveItem(at: url, to: uniqueURL)
            url.stopAccessingSecurityScopedResource()
            return uniqueURL
        } catch {
            url?.stopAccessingSecurityScopedResource()
            print("Error: \(error.localizedDescription)")
            throw error
        }
    }
}
//
//extension String {
//    static var blockedRenameWords : Set<String> {
//        return  withCheckedContinuation { continuation in
//            BOF_SwiftData.shared.getBlockedRenameWords()
//        }
//    }
//}
