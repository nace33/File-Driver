//
//  DriveDelegate.NewFolder.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/23/25.
//


//MARK: - New Folder
import BOF_SecretSauce
import SwiftUI
import GoogleAPIClientForREST_Drive


extension DriveDelegate {
    var canCreateNewFolder : Bool {
        stack.last != nil
    }
    func performActionNewFolder() {
        showNewFolderSheet = true
    }
    func createNewFolder(_ name:String, parentID:String) async throws -> GTLRDrive_File  {
        do {
            let newFolder = try await Drive.shared.create(folder: name, in:parentID)
            files.append(newFolder)
            sortFiles()
            return newFolder
        } catch {
            throw error
        }
    }
    @ViewBuilder var newFolderView : some View {
        TextSheet(title: "New Folder", prompt: "Create") { name in
            do {
                guard let parentID = self.stack.last?.id else { throw NSError.quick("No Parent ID")}
                let newFolder = try await self.createNewFolder(name, parentID:parentID)
                if self.moveSelectedFilesIntoFolder, self.selection.count > 1 {
                    self.moveSelectedFilesIntoFolder = false
                    let ids = self.selection.map(\.id)
                    try await self.move(ids: ids, newParentID:newFolder.id)
                }
                return nil
            } catch {
                return error
            }
        }
    }
}
