//
//  Contact.Label.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/10/25.
//

import Foundation
import GoogleAPIClientForREST_Drive

public extension Contact {
    struct Label : Hashable {
        var status : DriveLabel.Status
        var client : DriveLabel.ClientStatus
        var firstName : String
        var lastName : String
        var groupName : String
        var iconID    : String

        //This is not in the drive label, it is stored to indicate new icon needs to be uploaded
        var imageData   : Data?

        
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
        static func new() -> Contact.Label {
           Contact.Label(status: .active, client: .notAClient, firstName: "New Contact", lastName: "", groupName: "", iconID:"")
        }
       
        var labelFieldModifications : [GTLRDrive_LabelFieldModification] {
            var mods = [GTLRDrive_LabelFieldModification]()
            
            if let mod =  Drive.shared.label(modify: DriveLabel.status.rawValue, value: status.rawValue, valueType: .selection) {
                mods.append(mod)
            }
            if let mod =  Drive.shared.label(modify: DriveLabel.client.rawValue, value: client.rawValue, valueType: .selection) {
                mods.append(mod)
            }
            
            if let mod =  Drive.shared.label(modify: DriveLabel.firstName.rawValue, value:firstName, valueType: .text) {
                mods.append(mod)
            }
            
            if let mod =  Drive.shared.label(modify: DriveLabel.lastName.rawValue, value:lastName, valueType: .text) {
                mods.append(mod)
            }
    
            
  
            
            if let mod =  Drive.shared.label(modify: DriveLabel.groupName.rawValue, value:groupName, valueType: .text) {
                mods.append(mod)
            }
            
            if let mod =  Drive.shared.label(modify: DriveLabel.iconID.rawValue, value:iconID, valueType: .text) {
                mods.append(mod)
            }
            
    
     
            return mods
          }
        var labelModification       : GTLRDrive_LabelModification {
            Drive.shared.label(modify: DriveLabel.id.rawValue, fieldModifications: labelFieldModifications)
        }
    }
}

public extension Contact.Label {
    init?(file:GTLRDrive_File) {
        typealias DriveLabel = Contact.DriveLabel
        guard let label      = file.label(id: DriveLabel.id.rawValue) else { return nil }
        guard let statusStr  = label.value(fieldID: DriveLabel.status.rawValue) else { return nil }
        guard let status     = DriveLabel.Status(rawValue: statusStr) else { return nil }
        guard let clientStr  = label.value(fieldID: DriveLabel.client.rawValue) else { return nil }
        guard let client     = DriveLabel.ClientStatus(rawValue: clientStr) else { return nil }
        guard let firstName  = label.value(fieldID: DriveLabel.firstName.rawValue) else { return nil }
        //Optionals
        let lastName   = label.value(fieldID: DriveLabel.lastName.rawValue)  ?? ""
        let groupName  = label.value(fieldID: DriveLabel.groupName.rawValue) ?? ""
        let iconID     = label.value(fieldID: DriveLabel.iconID.rawValue)  ?? ""
        self = .init(status: status,
                     client: client,
                     firstName: firstName,
                     lastName: lastName,
                     groupName: groupName,
                     iconID: iconID)
    }
  
}
