//
//  Research.Label.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import Foundation
import GoogleAPIClientForREST_Drive

extension Research {
    struct Label : Hashable {
        var status      : DriveLabel.Status
        var category    : String
        var subCategory : String
        var timesUsed   : Int
 
        static func new(name:String = "") -> Research.Label {
            Research.Label(status: .draft, category: "", subCategory: "", timesUsed: 0)
        }
       
        var labelFieldModifications : [GTLRDrive_LabelFieldModification] {
            var mods = [GTLRDrive_LabelFieldModification]()
            if let mod =  Drive.shared.label(modify:DriveLabel.status.rawValue, value: status.rawValue, valueType: .selection) {
                mods.append(mod)
            }
            if let mod =  Drive.shared.label(modify:DriveLabel.category.rawValue, value:category, valueType: .text) {
                mods.append(mod)
            }
            if let mod =  Drive.shared.label(modify:DriveLabel.subCategory.rawValue, value:subCategory, valueType: .text) {
                mods.append(mod)
            }
            if let mod =  Drive.shared.label(modify:DriveLabel.timesUsed.rawValue, value:timesUsed, valueType: .integer) {
                mods.append(mod)
            }
            return mods
          }
        var labelModification       : GTLRDrive_LabelModification {
            Drive.shared.label(modify: DriveLabel.id.rawValue, fieldModifications: labelFieldModifications)
        }
    }
}
