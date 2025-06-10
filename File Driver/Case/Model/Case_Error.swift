//
//  Case_Error.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/16/25.
//

import Foundation


public enum Case_Error: Error {
    case notFound
    case nameIsEmpty
    case folderExistsWithName(String)
    case unableToCreateFolder
    case unableToCreateFolderFromValues
    case unableToAddFolderToCaseSpreadsheet
    case unableToRenameFolder
    case unableToUpdateCaseSpreadsheet
    case unableToDeleteFolder
    
    //Delete Folder
    case cannotDeleteFolderThatIsNotEmpty
    case cannotDeleteFolderFromCaseSpreadsheet
    
    var localizedDescription: String {
        switch self {
        case .notFound:
            return "Case not found"
        case .nameIsEmpty:
            return "You must provide a name"
        case .folderExistsWithName(let name):
            return "Folder with name \(name) already exists"
        case .unableToCreateFolder:
            return "Unable to create folder"
        case .unableToCreateFolderFromValues:
            return "Unable to create folder from values"
        case .unableToAddFolderToCaseSpreadsheet:
            return "Unable to add folder to case spreadsheet"
        case .unableToRenameFolder:
            return "Unable to rename folder"
        case .unableToDeleteFolder:
            return "Unable to delete folder"
        case .unableToUpdateCaseSpreadsheet:
            return "Unable to update case spreadsheet"
        case .cannotDeleteFolderThatIsNotEmpty:
            return "Cannot delete folder that is not empty"
        case .cannotDeleteFolderFromCaseSpreadsheet:
            return "Cannot delete folder from case spreadsheet"
        }
    }
}
