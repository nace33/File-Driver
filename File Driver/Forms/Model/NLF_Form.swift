//
//  Form_Label.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/25/25.
//

import Foundation
import GoogleAPIClientForREST_Drive
import SwiftUI

public
struct NLF_Form : Identifiable, Hashable {

    //GTLRDrive_File
    let file        : GTLRDrive_File
    public var id   : String { file.id }
    var title       : String
    
    //Label
    var label : Label
    
    //Drive Label, conveinence
    private var labelFieldModifications : [GTLRDrive_LabelFieldModification] { label.labelFieldModifications }
    var labelModification       : GTLRDrive_LabelModification { label.labelModification }
   

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
        let subCategory = label.value(fieldID: DriveLabel.subCategory.rawValue)          ?? ""
        let note         = label.value(fieldID: DriveLabel.note.rawValue)                ?? ""
        let reference    = label.value(fieldID: DriveLabel.fileDriverReference.rawValue) ?? ""
        
        //GTLRDrive_File
        self.file        = file
        self.title       = file.title
        
        //Drive_Label
        self.label = Label(status: status,
                                     category: category,
                                     subCategory: subCategory,
                                     timesUsed: timesUsed,
                                     lastUsed: lastUsed,
                                     lastUsedBy:lastUsedBy,
                                     note: note,
                                     reference: reference)
    }
    
    init(type:GTLRDrive_File.MimeType, name:String) {
        self.file = GTLRDrive_File()
        self.file.mimeType  = type.rawValue
        self.file.name      = name
        self.title          = name
        
        self.label = Label.new()
    }
}

//MARK: Print
extension NLF_Form {
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

