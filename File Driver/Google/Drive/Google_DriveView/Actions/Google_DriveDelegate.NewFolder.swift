//
//  Google_DriveDelegate.NewFolder.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/23/25.
//


//MARK: - New Folder
import BOF_SecretSauce
import SwiftUI
import GoogleAPIClientForREST_Drive


extension Google_DriveDelegate {
    var canCreateNewFolder : Bool {
        stack.last != nil
    }
    func performActionNewFolder() {
        showNewFolderSheet = true
    }
    func createNewFolder(_ name:String, parentID:String) async throws  {
        do {
            let newFolder = try await Google_Drive.shared.create(folder: name, in:parentID)
             files.append(newFolder)
            sortFiles()
        } catch {
            throw error
        }
    }
    @ViewBuilder var newFolderView : some View {
        TextSheet(title: "New Folder", prompt: "Create") { name in
            do {
                guard let parentID = self.stack.last?.id else { throw NSError.quick("No Parent ID")}
                try await self.createNewFolder(name, parentID:parentID)
                return nil
            } catch {
                return error
            }
        }
    }
}
