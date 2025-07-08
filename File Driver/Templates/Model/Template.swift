//
//  Template.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import Foundation
import GoogleAPIClientForREST_Drive
import SwiftUI

public
struct Template : Identifiable, Hashable {

    //GTLRDrive_File
    let file        : GTLRDrive_File
    public var id   : String { file.id }
    var title       : String { label.filename }
    
    //Label
    var label : Label
    
    //Drive Label, conveinence
    private var labelFieldModifications : [GTLRDrive_LabelFieldModification] { label.labelFieldModifications }
    var labelModification       : GTLRDrive_LabelModification { label.labelModification }
   
}


//MARK: Inits
extension Template {
    static func new() -> Template {
        let file = GTLRDrive_File()
        file.name = "New File"
        file.identifier = UUID().uuidString
        return .init(file: file, label: .new())
    }
    //Inits
    init?(file:GTLRDrive_File) {
        //required via Drive_Label - https://admin.google.com/ac/dc/labels/jkgGNqsZne1RFsBNYA7hMrTXROf966QGm8RRNNEbbFcb
        guard let label       = file.label(id: DriveLabel.id.rawValue) else { return nil }
        guard let statusStr   = label.value(fieldID: DriveLabel.status.rawValue) else { return nil }
        guard let status      = DriveLabel.Status(rawValue: statusStr) else { return nil }
        guard let category    = label.value(fieldID: DriveLabel.category.rawValue) else { return nil }
        guard let usedStr     = label.value(fieldID: DriveLabel.timesUsed.rawValue) else { return nil }
        guard let timesUsed   = Int(usedStr) else { return nil }
        guard let lastUsedStr = label.value(fieldID: DriveLabel.lastUsed.rawValue) else { return nil } //format YYYY-MM-DD
        guard let lastUsed    = Date(string: lastUsedStr, format: .yyyymmdd) else { return nil }
        guard let lastUsedBy  = label.value(fieldID: DriveLabel.lastUsedBy.rawValue) else { return nil }
        
        //Optional Drive_Label
        let subCategory       = label.value(fieldID: DriveLabel.subCategory.rawValue)         ?? ""
        let note              = label.value(fieldID: DriveLabel.note.rawValue)                ?? ""
        let reference         = label.value(fieldID: DriveLabel.fileDriverReference.rawValue) ?? ""
        
        //GTLRDrive_File
        self.file        = file
        
        //Drive_Label
        self.label = Label(status: status,
                                     category: category,
                                     subCategory: subCategory,
                                     timesUsed: timesUsed,
                                     lastUsed: lastUsed,
                                     lastUsedBy:lastUsedBy,
                                     note: note,
                                     reference: reference,
                                     filename: file.title)
    }

    init(type:GTLRDrive_File.MimeType, name:String) {
        self.file = GTLRDrive_File()
        self.file.mimeType  = type.rawValue
        self.file.name      = name
        
        self.label = Label.new()
    }
    func copy(file:GTLRDrive_File) {
        self.file.parents        = file.parents
        self.file.name           = file.name
        self.file.identifier     = file.identifier
        self.file.driveId        = file.driveId
        self.file.mimeType       = file.mimeType
        self.file.size           = file.size
        self.file.labelInfo      = file.labelInfo
        self.file.fileExtension  = file.fileExtension
        self.file.modifiedTime   = file.modifiedTime
        self.file.webViewLink    = file.webViewLink
        self.file.webContentLink = file.webContentLink
        self.file.exportLinks    = file.exportLinks
        self.file.thumbnailLink  = file.thumbnailLink
        self.file.modifiedTime   = file.modifiedTime
    }
    init(copyFile:GTLRDrive_File) {
        self = .init(type: copyFile.mime, name: copyFile.title)
        self.copy(file:copyFile)
    }
}
//MARK: Print
extension Template {
    func printAll() {
        print("File:\t\(file.title)")
        print("\t\tID:\t\t\t\t\(id)")
        print("\t\tStatus:\t\t\t\(label.status.title)")
        print("\t\tCategory:\t\t\(label.category)")
        print("\t\tTimes Used:\t\t\(label.timesUsed)")
        print("\t\tLast Used:\t\t\(label.lastUsed)")
        print("\t\tLast Used By:\t\(label.lastUsedBy)")
        print("\t\tNote:\t\t\(label.note)")
        print("\t\tReference:\t\t\(label.reference)")
    }
}




