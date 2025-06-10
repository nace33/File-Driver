//
//  Label.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//

import Foundation
import GoogleAPIClientForREST_Drive



public extension NLF_Contact {
    struct Label : Hashable {
        var status : DriveLabel.Status
        var client : DriveLabel.ClientStatus
        var firstName : String
        var lastName : String
        var updateID : String
        var groupName : String
        var iconID    : String
        var timesUsed : Int

        //Optional values are: lastName, parentID, groupName, iconLink
        //They are not optional here so there is a default value for UI/Sorting/Filtering purposes
    
        var name : String {
            if lastName.isEmpty { firstName }
            else { firstName + " " + lastName}
        }
        var nameReversed : String {
            if lastName.isEmpty { firstName }
            else { lastName + ", " + firstName}
        }
        static func new() -> NLF_Contact.Label {
            NLF_Contact.Label(status: .active, client: .notAClient, firstName: "New Contact", lastName: "", updateID: UUID().uuidString, groupName: "", iconID:"", timesUsed: 0)
   
        }
       
        var labelFieldModifications : [GTLRDrive_LabelFieldModification] {
            var mods = [GTLRDrive_LabelFieldModification]()
            
            if let mod =  Google_Drive.shared.label(modify: DriveLabel.status.rawValue, value: status.rawValue, valueType: .selection) {
                mods.append(mod)
            }
            if let mod =  Google_Drive.shared.label(modify: DriveLabel.client.rawValue, value: client.rawValue, valueType: .selection) {
                mods.append(mod)
            }
            
            if let mod =  Google_Drive.shared.label(modify: DriveLabel.firstName.rawValue, value:firstName, valueType: .text) {
                mods.append(mod)
            }
            
            if let mod =  Google_Drive.shared.label(modify: DriveLabel.lastName.rawValue, value:lastName, valueType: .text) {
                mods.append(mod)
            }
    
            
            //Always update the updateID value when the drive label is updated.
            if let mod =  Google_Drive.shared.label(modify: DriveLabel.updateID.rawValue, value:Date.idString, valueType: .text) {
                mods.append(mod)
            }
            
            if let mod =  Google_Drive.shared.label(modify: DriveLabel.groupName.rawValue, value:groupName, valueType: .text) {
                mods.append(mod)
            }
            
            if let mod =  Google_Drive.shared.label(modify: DriveLabel.iconID.rawValue, value:iconID, valueType: .text) {
                mods.append(mod)
            }
            
            if let mod =  Google_Drive.shared.label(modify: DriveLabel.timesUsed.rawValue, value: timesUsed, valueType: .integer) {
                mods.append(mod)
            }
     
     
            return mods
          }
        var labelModification       : GTLRDrive_LabelModification {
            Google_Drive.shared.label(modify: DriveLabel.id.rawValue, fieldModifications: labelFieldModifications)
        }
    }
}
