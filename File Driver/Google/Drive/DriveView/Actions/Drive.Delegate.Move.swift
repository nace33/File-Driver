//
//  DriveDelegate.Move.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/23/25.
//

import Foundation
import GoogleAPIClientForREST_Drive

//MARK: - Move
extension DriveDelegate {
    func canDrag(file:GTLRDrive_File) -> Bool {
        guard let driveID = file.driveId else { return false }
        return file.id != driveID
    }
    func canMove(id:String?, newParentID:String) -> Bool {
        guard let id else { return false }
        guard id != newParentID else { return false }
        guard let index = files.firstIndex(where: {$0.id == id }) else { return false }
        guard let currentParentID = files[index].parents?.first else { return false }
        guard currentParentID != newParentID else { return false }
        return true
    }

    fileprivate struct MoveItem : Identifiable {
        var id : String { fileID }
        let fileID : String
        let parentID : String
        let destinationID : String
        var tuple : (fileID:String, parentID:String, destinationID:String) {
            (fileID:id, parentID:parentID, destinationID:destinationID)
        }
    }
    func move(ids:[String], newParentID:String) async throws  {
        let moveItems : [MoveItem] = ids.compactMap { id in
            guard canMove(id: id, newParentID: newParentID) else { return nil}
            guard let index = files.firstIndex(where: {$0.id == id }) else { return nil }
            guard let currentParentID = files[index].parents?.first else { return nil}
           
            removeFromSelection([files[index]])
            return MoveItem(fileID: id, parentID: currentParentID, destinationID: newParentID)
        }
        var priorFiles : [GTLRDrive_File] = []
        do {
            guard moveItems.isNotEmpty else { throw NSError.quick("No files to move.") }
            guard moveItems.count == ids.count else { throw NSError.quick("Could not locate some files to move.") }
         
            //add to UI array
            moveItemIDs.append(newParentID)
            
            //remove from UI Arrays
            let idsOfFilesToMove = moveItems.compactMap { $0.id }
            files.removeAll { file in
                if idsOfFilesToMove.contains(file.id) {
                    priorFiles.append(file)
                    return true
                } else {
                    return false
                }
            }
            let tuples = moveItems.compactMap(\.tuple)
            _ = try await Drive.shared.move(tuples: tuples)
            
            moveItemIDs.removeAll(where: {$0 == newParentID})
        } catch {
            moveItemIDs.removeAll(where: {$0 == newParentID})
            if priorFiles.count > 0 {
                files.append(contentsOf: priorFiles)
                sortFiles()
            }
            throw error
        }
    }
}
