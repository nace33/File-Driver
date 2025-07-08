//
//  DriveDelegate.Rename.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/23/25.
//

import BOF_SecretSauce
import SwiftUI
import GoogleAPIClientForREST_Drive

//MARK: - Rename
extension DriveDelegate {
    internal struct RenameItem : Identifiable {
        let id = UUID().uuidString
        let files:[GTLRDrive_File]
    }
    
    //Calls
    internal func canRename(file:GTLRDrive_File?) -> Bool {
        guard let file                  else { return false }
        guard let dID = file.driveId    else { return false }
        guard file.id != dID            else { return false }
        return file != stack.last
    }
    internal func performActionRename(files:[GTLRDrive_File])  {
        self.renameItem = .init(files: files)
    }
    
    
    //Single file action
    fileprivate func rename(_ name:String, id:String) async throws {
        do {
            let renamedFile = try await Drive.shared.rename(id: id, newName: name)
            if let index = files.firstIndex(where: {$0.id == id}) {
                files.remove(at: index)
                files.append(renamedFile)
                sortFiles()
            }
        } catch {
            throw error
        }
    }
    
    
    //View BUilders
    @ViewBuilder internal    func renameView(_ item:RenameItem) -> some View {
        if item.files.count == 1 {
            renameSingleView(item.files.first!)
        } else {
            renameMultipleFiles(item.files)
        }
    }
    @ViewBuilder fileprivate func renameSingleView(_ item:GTLRDrive_File) -> some View {
        TextSheet(title: "Rename", prompt: "Save", string:item.title) { newName in
            do { try await self.rename(newName, id:item.id); return nil}
            catch { return error }
        }
    }
    @ViewBuilder fileprivate func renameMultipleFiles(_ items:[GTLRDrive_File]) -> some View {
        Drive_Rename(files:items, saveOnServer: true, isSheet: true) { renamedFiles in
            for renamedFile in renamedFiles {
                if let index = self.files.firstIndex(where: { $0.id == renamedFile.id }) {
                    self.files[index].name = renamedFile.name
                }
            }
            self.renameItem = nil
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { self.renameItem = nil }
            }
        }
    }
}

