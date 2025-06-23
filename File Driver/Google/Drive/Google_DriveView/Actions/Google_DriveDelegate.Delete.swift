//
//  Google_DriveDelegate.Delete.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/23/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

//MARK: - Delete
extension Google_DriveDelegate {
    func canDelete(file:GTLRDrive_File?) -> Bool {
        guard let file                  else { return false }
        guard let dID = file.driveId    else { return false }
        guard file.id != dID            else { return false }
        return file != stack.last
    }
    
    
    internal struct DeleteItem : Identifiable {
        let id = UUID().uuidString
        let files : [GTLRDrive_File]
        var title : String {
            if files.count == 1 {
                return "'" + files[0].title + "'"
            }
            return "\(files.count) files"
        }
        var subDescription : String {
            if files.count == 1 {
                return "this \(files[0].isFolder ? "folder" : "file")"
            }
            return "these \(files.count) files"
        }
    }
    internal func performActionDelete(files:[GTLRDrive_File])  {
        self.deleteItem = .init(files: files)
    }

    func delete(_ item:DeleteItem) async throws {
        removeFromSelection(item.files)
        do {
            let idsToDelete = item.files.map(\.id)
            guard try await Google_Drive.shared.delete(ids: idsToDelete) else { return }
            
            files.removeAll { file in
                idsToDelete.contains(file.id)
            }

        } catch {
            throw error
        }
    }
    @ViewBuilder func deleteView(_ item:DeleteItem) -> some View {
        ConfirmationSheet(title: "Move \(item.title) to Trash",
                          message: "Google Drive will permanently delete \(item.subDescription) in 30 days.  Prior to permanent deletion, \(item.subDescription) can be restored from Drive's Trash folder.",
                          prompt: "Move to trash") {
            do {
                try await self.delete(item)
                self.deleteItem = nil
            } catch { throw error }
        }
    }

}
