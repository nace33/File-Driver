//
//  Case.swift
//  FD_Filing
//
//  Created by Jimmy Nasser on 4/16/25.
//

import Foundation
import GoogleAPIClientForREST_Drive

@Observable
final class Case : Identifiable {
    let id          : String     //drive ID
    let file        : GTLRDrive_File
    let parentID    : String
    let driveID     : String
    var driveLabel  : DriveLabel
    var title       : String { driveLabel.title }
    

    init(id:String, parentID:String, driveID:String, driveLabel:DriveLabel, file:GTLRDrive_File) {
        self.id = id
        self.driveID = driveID
        self.parentID = parentID
        self.driveLabel = driveLabel
        self.file = file
    }
    convenience init?(_ file:GTLRDrive_File) {
        guard let id = file.identifier,
              let driveID = file.driveId,
              let parentID = file.parents?.first,
              let driveLabel = DriveLabel(driveLabel: file.label(id: Case.DriveLabel.Label.id.rawValue)) else { return nil }
        
        self.init(id: id, parentID:parentID, driveID: driveID, driveLabel: driveLabel, file: file)
    }
        
    //call load() to populate
    //represents the rows in each sheet in the Spreadsheet
    var folders  : [Folder]   = []
    var contacts : [Contact]  = []
    var tags     : [Tag]      = []
    
    //folderID
    var folderID : String {
        return if !driveLabel.folderID.isEmpty {
            driveLabel.folderID
        } else if let parentID = file.parents?.first, parentID != file.driveId {
            parentID
        } else {
            file.driveId ?? ""
        }
    }
}

//MARK: Hashable {
extension Case : Hashable {
    static func == (lhs: Case, rhs: Case) -> Bool { lhs.id == rhs.id  }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
