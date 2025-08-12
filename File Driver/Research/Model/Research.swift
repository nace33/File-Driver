//
//  Research.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import Foundation
import GoogleAPIClientForREST_Drive

struct Research : Identifiable, Hashable {
    let id      : String
    let file    : GTLRDrive_File
    var title   : String { file.titleWithoutExtension }
    var label   : Label
    
    //Drive Label, conveinence
    private var labelFieldModifications : [GTLRDrive_LabelFieldModification] { label.labelFieldModifications }
    var labelModification       : GTLRDrive_LabelModification { label.labelModification }
}


extension Research {
    init?(file:GTLRDrive_File) {
        guard let label = file.label(id: DriveLabel.id.rawValue) else { return nil }
        guard let statusStr   = label.value(fieldID: DriveLabel.status.rawValue) else { return nil }
        guard let status      = DriveLabel.Status(rawValue: statusStr) else { return nil }
        guard let category    = label.value(fieldID: DriveLabel.category.rawValue) else { return nil }
        guard let usedStr     = label.value(fieldID: DriveLabel.timesUsed.rawValue) else { return nil }
        guard let timesUsed   = Int(usedStr) else { return nil }
       
        let subCategory       = label.value(fieldID: DriveLabel.subCategory.rawValue) ?? ""
        self.id               = file.id
        self.file             = file
        
        
        self.label      = Label(status: status, category: category, subCategory: subCategory, timesUsed: timesUsed)

    }
}
