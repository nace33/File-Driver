//
//  Case_Categories.swift
//  FD_Filing
//
//  Created by Jimmy Nasser on 4/16/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

//MARK: Folder Struct
extension Case {
    struct Folder : Identifiable, Hashable  {
        let id      : String //Drive ID of folder
        let parentID: String //Drive ID of parent
        var name    : String //name of folder
        
        //local not from google sheet
        let isSuggestion : Bool
        
        //inits
        init(id:String, parentID:String, name:String) {
            self.id = id
            self.parentID = parentID
            self.name = name
            isSuggestion = false
        }
        init(suggestion:Suggestion, proposedParentID:String? = nil) {
            id = UUID().uuidString
            parentID = proposedParentID ?? ""
            name = suggestion.title
            isSuggestion = true
        }
        init?(_ folder:GTLRDrive_File) {
            guard folder.isFolder else { return nil }
            guard let id = folder.identifier else { return nil }
            guard let parentID = folder.parents?.first else { return nil }
            guard let name = folder.name else { return nil }
            self.init(id: id, parentID: parentID, name: name)
        }
    }
}


//MARK: Load
extension Case {
    func load(folders:[[String]]) {
        
    }
}


//MARK: Get
extension Case {
    var rootFolders : [Folder] { folders.filter{$0.parentID == parentID}  }
    func getFolder(id:Folder.ID) -> Folder? { folders.first(where: {$0.id == id})}
    func children(of folder:Folder) -> [Folder] { folders.filter{$0.parentID == folder.id}  }
    func path(of target:Folder) -> [Folder] {
        guard target.parentID.isEmpty == false else { return [] }
        var parentID :String? = target.parentID
        var parents = [Folder]()
        while parentID != nil {
            if let found =  folders.filter({ $0.id == parentID }).first{
                parents.append(found)
                parentID = found.parentID.isEmpty ? nil : found.parentID
            } else {
                parentID = nil
            }
        }
        return parents
    }
}



//MARK: Create
extension Case {
    func canCreate(folder name:String, in parent:Folder?) -> Bool {
        guard name.isEmpty == false else { return false }
        if let parent {
            let children = children(of: parent)
            let names = children.compactMap { $0.name.lowercased() }
            return names.contains(name.lowercased()) == false
        } else {
            let names = rootFolders.compactMap { $0.name.lowercased() }
            return names.contains(name.lowercased()) == false
        }
    }
    func create(folder name:String, in parent:Folder?) async throws(Case_Error) -> Folder {
        do throws(Case_Error){
            guard name.isEmpty == false               else { throw Case_Error.nameIsEmpty }
            guard canCreate(folder: name, in: parent) else { throw Case_Error.folderExistsWithName(name)}
            let parentID = parent?.id ?? driveID
           
            //Create a folder in Google Drive
            let driveFolder = try await createDriveFolder(name: name, parentID: parentID)

            //Add a Folder row to the Case Spreadsheet
            let newFolder = Folder(id: driveFolder.id, parentID: parentID, name: name)
            
            //Update the local model
            self.folders.append(newFolder)
     
            //return the new model
            return newFolder
        } catch {
            throw error
        }
    }
    fileprivate func createDriveFolder(name:String, parentID:String) async throws(Case_Error) -> GTLRDrive_File {
        do {
           return try await Google_Drive.shared.create(folder: name, in:parentID)
        } catch {
            print(#function + " " + error.localizedDescription)
            throw Case_Error.unableToCreateFolder
        }
    }

}


//MARK: Update
extension Case {

    fileprivate func update(_ folder:Folder, newName: String) async throws(Case_Error) {
        do {
          _ = try await Google_Drive.shared.rename(id: folder.id, newName: newName)
        } catch { throw Case_Error.unableToRenameFolder }
    }

}


//MARK: Delete
extension Case {
    func canDelete(folder:Folder) -> Bool {
        children(of: folder).isEmpty
    }
    func delete(folder:Folder) async throws(Case_Error) {
        do throws(Case_Error) {
            guard children(of: folder).isEmpty else { throw Case_Error.cannotDeleteFolderThatIsNotEmpty }
            try await deleteFromCaseSpreadsheet(folder)
            try await deleteFromDrive(folder)
        } catch {
            throw error
        }
    }
    fileprivate func deleteFromCaseSpreadsheet(_ folder:Folder) async throws(Case_Error) {
        do {
            _ = try await Google_Sheets.shared.delete(rowID: folder.id, sheetName: Sheet.folders.title, spreadsheetID: id)
        } catch {
            throw Case_Error.unableToUpdateCaseSpreadsheet
        }
    }
    fileprivate func deleteFromDrive(_ folder:Folder) async throws(Case_Error) {
        do {
            guard try await Google_Drive.shared.getContents(of:folder.id).isEmpty else {
                throw Case_Error.cannotDeleteFolderThatIsNotEmpty
            }
            _ = try await Google_Drive.shared.delete(ids: [folder.id])
        } catch {
            throw Case_Error.unableToDeleteFolder
        }
    }
}
