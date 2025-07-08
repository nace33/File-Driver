//
//  Template.Label.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import Foundation

import Foundation
import GoogleAPIClientForREST_Drive

public extension Template {
    struct Label : Hashable {
        var status      : DriveLabel.Status
        var category    : String
        var subCategory : String
        var timesUsed   : Int
        var lastUsed    : Date
        var lastUsedBy  : String
        var note        : String
        var reference   : String
        
        
        //Not in DriveLabel - just a convenince
        var filename    : String
        static func new() -> Template.Label {
            Template.Label(status: .drafting,
                            category: "",
                            subCategory: "",
                            timesUsed: 0,
                            lastUsed: Date(),
                            lastUsedBy: Google.shared.user?.profile?.email ?? "",
                            note: "",
                            reference: "",
                           filename: "")
        }
       
        var labelFieldModifications : [GTLRDrive_LabelFieldModification] {
            var mods = [GTLRDrive_LabelFieldModification]()
            if let mod =  Drive.shared.label(modify: DriveLabel.status.rawValue, value: status.rawValue, valueType: .selection) {
                mods.append(mod)
            }
            if let mod =  Drive.shared.label(modify: DriveLabel.category.rawValue, value:category, valueType: .text) {
                mods.append(mod)
            }
            if let mod =  Drive.shared.label(modify: DriveLabel.subCategory.rawValue, value:subCategory, valueType: .text) {
                mods.append(mod)
            }
            if let mod =  Drive.shared.label(modify: DriveLabel.timesUsed.rawValue, value: timesUsed, valueType: .integer) {
                mods.append(mod)
            }
            if let mod =  Drive.shared.label(modify: DriveLabel.lastUsed.rawValue, value: lastUsed, valueType: .date) {
                mods.append(mod)
            }
            if let mod =  Drive.shared.label(modify: DriveLabel.lastUsedBy.rawValue, value:lastUsedBy, valueType: .text) {
                mods.append(mod)
            }
            if let mod =  Drive.shared.label(modify: DriveLabel.note.rawValue, value:note, valueType: .text) {
                mods.append(mod)
            }
            if let mod =  Drive.shared.label(modify: DriveLabel.fileDriverReference.rawValue, value:reference, valueType: .text) {
                mods.append(mod)
            }
            return mods
          }
        var labelModification       : GTLRDrive_LabelModification {
            Drive.shared.label(modify: DriveLabel.id.rawValue, fieldModifications: labelFieldModifications)
        }
    }
}
