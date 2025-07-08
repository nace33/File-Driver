//
//  GTLR_DriveFile_Ext.swift
//  Nasser Law Firm
//
//  Created by Jimmy Nasser on 3/22/25.
//

import Foundation
import UniformTypeIdentifiers

import GoogleAPIClientForREST_Drive

//MARK: -ID

extension GTLRDrive_File : @retroactive Identifiable   {
    public var id: String { identifier ?? "No Identifier Found"}
    public var title : String { name ?? "No Name" }
    public var titleWithoutExtension : String {
        if let fileExtension { return title.replacingOccurrences(of: ".\(fileExtension)", with: "")}
        return title
    }
    var targetID : String { shortcutDetails?.targetId ?? id}
    
    var fileSizeString : String {
        guard let size = size?.intValue else { return "0 Bytes" }
        return size.fileSizeString
    }
}

//MARK: -MimeType
public extension GTLRDrive_File   {
    enum MimeType : String, CaseIterable, Identifiable, Comparable {
        public static func < (lhs: GTLRDrive_File.MimeType, rhs: GTLRDrive_File.MimeType) -> Bool {
            lhs.id == rhs.id
        }
        
        public var id : String { rawValue }
        //https://developers.google.com/drive/api/guides/mime-types
        case file       = "application/vnd.google-apps.file"
        case folder     = "application/vnd.google-apps.folder"
        case doc        = "application/vnd.google-apps.document"
        case sheet      = "application/vnd.google-apps.spreadsheet"
        case slides     = "application/vnd.google-apps.presentation"
        case shortcut   = "application/vnd.google-apps.shortcut"
        case pdf        = "application/pdf"
        case email      = "message/rfc822"
//        case audio      = "application/vnd.google-apps.audio"
        case tpShortcut = "application/vnd.google-apps.drive-sdk"
        case drawing    = "application/vnd.google-apps.drawing"
        case form       = "application/vnd.google-apps.form"
        case fusiontable = "application/vnd.google-apps.fusiontable"
        case jam        = "application/vnd.google-apps.jam"
        case map        = "application/vnd.google-apps.map"
        case photo      = "application/vnd.google-apps.photo"
        case script     = "application/vnd.google-apps.script"
        case site       = "application/vnd.google-apps.site"
        case video = "video"
        case image = "image"
        case audio = "audio"
//        case video      = "application/vnd.google-apps.video"
        case microsoftWord = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case openDocumentText = "application/vnd.oasis.opendocument.text"
        case richText = "application/rtf"
        case plainText =  "text/plain"
        case zip = "application/zip"
        case epub = "application/epub+zip"
        case microsoftExcel = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case openDocumentSpreadsheet = "application/x-vnd.oasis.opendocument.spreadsheet"
        case CSV = "text/csv"
        case TSV = "text/tab-separated-values"
        case microsoftPowerPoint = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case openDocumentPresentation = "application/vnd.oasis.opendocument.presentation"
        case JPEG = "image/jpeg"
        case PNG = "image/png"
        case SVG = "image/svg+xml"
        case json = "application/vnd.google-apps.script+json"
        case unknown    = "null"
        static let googleTypes : [MimeType] = [.doc, .sheet, .slides]
        static var allTypesExceptFolder : [MimeType] {allCases.filter { $0 != .folder} }
        static let standardSearchTypes : [MimeType] = [
            .pdf, .doc, .sheet, .email, .folder, .image, .video, .audio, .shortcut, .zip
        ]
        var isGenericMedia : Bool {
            switch self {
            case .audio, .video, .image:
                true
            default:
                false
            }
        }
        var image : String {
            switch self {
            case .folder:
                return "folder"
            case .doc, .microsoftWord, .openDocumentText, .richText, .plainText:
                return "doc.text"
            case .sheet, .microsoftExcel, .openDocumentSpreadsheet:
                return "tablecells"
            case .slides, .openDocumentPresentation, .microsoftPowerPoint:
                return "square.grid.3x3.square"
            case .email:
                return "mail"
            case .shortcut:
                return "arrow.uturn.backward.square.fill"
            case .audio:
                return "music.quarternote.3"
            case .image, .JPEG, .PNG, .SVG, .photo:
                return "photo"
            case .video:
                return "video"
            case .zip:
                return "doc.zipper"
            default:
                return "doc"
            }
        }
        var title : String {
            switch self {
            case .file:
                "All Files"
            case .folder:
                "Folder"
            case .doc:
                "Google Doc"
            case .sheet:
                "Google Sheet"
            case .slides:
                "Google Slide"
            case .shortcut:
                "Shortcuts"
            case .pdf:
                "PDFs"
            case .email:
                "Email"
            case .audio:
                "Audio"
            case .tpShortcut:
                "Drive SDK"
            case .drawing:
                "Drawing"
            case .form:
                "Google Form"
            case .fusiontable:
                "Fusion Table"
            case .jam:
                "Jam"
            case .map:
                "Map"
            case .photo:
                "Photo"
            case .script:
                "App Script"
            case .site:
                "Google Site"
            case .video:
                "Video"
            case .microsoftWord:
                "Microsoft Word"
            case .openDocumentText:
                "Open Doc"
            case .richText:
                "Rich Text"
            case .plainText:
                "Plain Text"
            case .zip:
                "Archives (zip)"
            case .epub:
                "E-Pub"
            case .microsoftExcel:
                "Microsoft Excel"
            case .openDocumentSpreadsheet:
                "Open Doc Spreadsheet"
            case .CSV:
                "CSV - comma seperates values"
            case .TSV:
                "TSV - tab seperated values"
            case .microsoftPowerPoint:
                "Microsoft Powerpoint"
            case .openDocumentPresentation:
                "Open Doc Presentation"
            case .JPEG:
                "JPEG"
            case .PNG:
                "PNG"
            case .SVG:
                "SVG"
            case .json:
                "JSON"
            case .unknown:
                "Unknown"
            case .image:
                "Image"
            }
        }

    }
    var mime : MimeType { MimeType(rawValue: mimeType ?? "") ?? .unknown }
    var isFolder : Bool { mime == .folder }
    var isShortcutFolder : Bool {
        guard mime == .shortcut else { return false }
        guard let ogMimeStr = shortcutDetails?.targetMimeType,
              let ogMime    = GTLRDrive_File.MimeType(rawValue: ogMimeStr)  else { return false }
        return ogMime == .folder
    }
    var isLeaf: Bool { !isFolder }
    var isGoogleType : Bool { MimeType.googleTypes.contains(mime) }
    var imageString : String {
        if mime == .unknown {
            if mimeType?.contains("audio") ?? false {
                return MimeType.audio.image
            } else if mimeType?.contains("image") ?? mimeType?.contains("photo") ?? false {
                return MimeType.image.image
            }
            else if mimeType?.contains("video") ?? false {
                return MimeType.video.image
            }
        }
      return  mime.image
    }
}

//MARK: -URL
public extension GTLRDrive_File   {
    //See GTLRDrive_File.exportLinks
  
    var previewURL : URL {
//        if let webViewLink, let url = URL(string: webViewLink) {
//            return url.deletingLastPathComponent().appendingPathComponent("preview")
//        }
        return url.appendingPathComponent("preview")
    }
    var editURL : URL {
//        if let webViewLink, let url = URL(string: webViewLink) {
//            return url
//        }
        return url.appendingPathComponent("edit")
    }
    var showInDriveURL : URL {
        if isFolder {
             URL(string: "https://drive.google.com/drive/folders/\(id)")!
        }
        else if let parent = parents?.first {
             URL(string: "https://drive.google.com/drive/folders/\(parent)")!
        } else if let driveID = driveId {
             URL(string: "https://drive.google.com/drive/folders/\(driveID)")!
        } else {
            URL(string:"https://drive.google.com/file/d/\(id)")!
        }

    }

    var url : URL {
        switch mime {
        case .folder:
             URL(string: "https://drive.google.com/folders/\(id)")!
        case .doc:
             URL(string: "https://docs.google.com/document/d/\(id)")!
        case .sheet:
             URL(string: "https://docs.google.com/spreadsheets/d/\(id)")!
        case .slides:
             URL(string: "https://docs.google.com/presentation/d/\(id)")!
        default:
            URL(string:"https://drive.google.com/file/d/\(id)")!
        }
    }
    static let pdfExt = "/export?format=pdf" //send links that download as a pdf
    static func driveURL(id:String) -> URL {
        URL(string:"https://drive.google.com/file/d/\(id)")!
    }
    
    var downloadFilename : String {
        var filename = ""
        if isGoogleType {
            filename = (name ?? "Google Document") + ".pdf"
        } else {
            filename = name ?? "Untitled"
        }
        if let fileExtension = fileExtension,
           !filename.hasSuffix(fileExtension){
            filename += "." + fileExtension
        }
        return filename
    }
    func downloadURL(directory:URL) -> URL {
       directory.appending(path: downloadFilename, directoryHint: .notDirectory)
    }
    
    var thumbnailURL : URL? {
        guard let thumbnailLink, thumbnailLink.isEmpty == false else { return nil }
        return URL(string:thumbnailLink)
    }
    func iconURL(_ size:Int = 16) -> URL {
        //convenience instead of getting the 'iconLink' for every file fetched
        let str = "https://drive-thirdparty.googleusercontent.com/\(size)/type/\(mimeType ?? "")"
        return URL(string: str)!
    }
    

}

//MARK: -ICON
import SwiftUI
public extension GTLRDrive_File {
    @ViewBuilder var icon : some View {
        
        if Bundle.main.image(forResource: mime.title) == nil {
            Image(systemName: imageString)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(mime.title)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}


//MARK: -Query Helpers
public extension GTLRDrive_File {
    enum QueryField : String, CaseIterable {
        //IDs
        case id, driveId, parents
        static var ids : [QueryField] {[.id, .driveId, .parents]}
        
        //File Info
        case name, mimeType, shortcutDetails, size, labelInfo, fileExtension, modifiedTime, description
        static var fileInfo : [QueryField] {[.name, .mimeType, .shortcutDetails, .size, .labelInfo, .fileExtension, .modifiedTime, .description]}
        
        //Links
        case webViewLink, webContentLink, exportLinks, thumbnailLink
        static var links : [QueryField] {[ .webViewLink, .webContentLink, .exportLinks, .thumbnailLink ]}
        
        case appProperties
        static var defaults : String {
            fieldsString(QueryField.allCases, isFolder: false)
        }
        static func fieldsString(_ fields : [QueryField], isFolder:Bool) -> String {
            let string = fields.compactMap(\.rawValue).joined(separator: ",")
            return if isFolder {
                "files(\(string))"
            } else {
                string
            }
        }
    }
    static let queryFileFields   = QueryField.defaults
    static let queryFolderFields = "files(\(queryFileFields))"
}

//MARK: -Labels
public extension GTLRDrive_File {
    var labels : [GTLRDrive_Label]? { labelInfo?.labels }
  
    func labelFieldObject(label:GTLRDrive_Label) -> GTLRDrive_Label_Fields? { label.fields}
    func labelKeyedFields(fieldObject:GTLRDrive_Label_Fields) -> [String:GTLRDrive_LabelField]? {
        fieldObject.additionalProperties() as? [String: GTLRDrive_LabelField]
    }
    func labelField(id:String, label:GTLRDrive_Label) -> GTLRDrive_LabelField? {
        if let fieldObject = labelFieldObject(label: label),
           let keyedFields = labelKeyedFields(fieldObject: fieldObject) {
            return keyedFields[id]
        }
        return nil
    }

    func label(id:String) -> GTLRDrive_Label? {
        labels?.first(where:{ $0.identifier == id })
    }
    func label(fieldID:String) -> GTLRDrive_Label? {
        labels?.filter({ label in labelField(id: fieldID, label: label) != nil  }).first
    }
    
    
    func hasLabel(id:String) -> Bool {
        label(id: id) != nil
    }
    func hasLabelFieldValue(targetValue:String, fieldID:String? = nil) -> Bool {
        guard let labels, labels.isNotEmpty else { return false }
        if let fieldID {
            if let label = label(fieldID: fieldID),
               let field = label.field(id: fieldID) {
                return field.value == targetValue
            }
        } else {
            return labels.filter { $0.hasValue(targetValue: targetValue) }.isNotEmpty
        }
        return false
    }
}

extension GTLRDrive_Label {
    var keyedFields : [String:GTLRDrive_LabelField]? {
        fields?.additionalProperties() as? [String : GTLRDrive_LabelField]
    }
    var allFieldIDs : [String]? {
        if let keys = keyedFields?.keys {
            return Array(keys)
        }
        return nil
    }
    var allFields   : [GTLRDrive_LabelField]? {
        allFieldIDs?.compactMap { field(id: $0) }
    }
    var allValues   : [String]? {
        allFields?.compactMap { $0.value }
    }
    func field(id:String) -> GTLRDrive_LabelField? {
        keyedFields?[id]
    }
    func hasField(id:String) -> Bool {
        allFieldIDs?.contains(id) ?? false
    }
    func value(fieldID:String) -> String? {
        field(id: fieldID)?.value
    }
    
    func hasValue(targetValue:String, fieldID:String? = nil) -> Bool {
        if let fieldID {
            return value(fieldID:fieldID) == targetValue
        } else {
            return allValues?.first(where: { $0 == targetValue }) != nil
        }
    }
    static func hasValue(targetValue:String, fieldID:String? = nil, labels:[GTLRDrive_Label]) -> Bool {
        labels.filter { $0.hasValue(targetValue: targetValue, fieldID: fieldID)}.isNotEmpty
    }

}
extension GTLRDrive_LabelField {
    enum FieldType : String, CaseIterable { case dateString, integer, selection, text, user }
    var type : FieldType? {  FieldType(rawValue: valueType ?? "ERROR")}
    var value : String? {
        switch type {
        case .dateString:
            return dateString?.first?.stringValue
        case .integer:
            return "\(integer?.first ?? -33)"
        case .selection://does not work with multiple selection instances
            return selection?.first //may need to be cross referenced with values from the label itself
        case .text:
            return text?.first
        case .user://does not work with multiple users
            return user?.first?.displayName
        case .none:
            return "Error"
        }
    }
}
