//
//  EditCase.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct EditCase: View {
    @Binding var aCase : Case
    init(_ aCase : Binding<Case>) {
        _aCase = aCase
        _original = State(initialValue:Case(file: aCase.wrappedValue.file, label: aCase.wrappedValue.label))
    }
    @Environment(\.dismiss) var dismiss
    @State private var original : Case
    @State private var statusString = "Edit Case"
    @State private var moveToSharedDrive : Bool = false
    
    var body: some View {
        EditForm(title:statusString, prompt: "Update", style: .sheet, item: $original) { editItem in
            Section {
                TextField("Name", text:editItem.label.title)
                Picker("Type", selection: editItem.label.category) {
                    ForEach(Case.DriveLabel.Label.Field.Category.allCases, id: \.self) { category in
                        Text(category.title)
                    }
                }
                Picker("Status", selection: editItem.label.status) {
                    ForEach(Case.DriveLabel.Label.Field.Status.allCases, id: \.self) { status in
                        Text(status.title)
                    }
                }
            }
            if aCase.file.driveId != aCase.label.folderID {
                Section {
                    Toggle("Move to Shared Drive", isOn: $moveToSharedDrive)
                }
            }
        } canUpdate: { editItem in
            self.canUpdate(editItem.wrappedValue)
        } update: { editItem in
            try await self.update(editItem.wrappedValue)
        }
    }
}

//MARK: - Actions
extension EditCase {
    func canUpdate(_ editItem:Case) -> Bool {
        guard !moveToSharedDrive      else { return true  }
        guard !editItem.title.isEmpty else { return false }
        return aCase.label != editItem.label
    }
    func update(_ editItem:Case) async throws {
        var newDriveID : String? = nil
        do {
            
            if moveToSharedDrive {
                statusString = "Creating New Shared Drive"
                let newDrive = try await Drive.shared.sharedDrive(new: editItem.label.folderTitle)
                editItem.label.folderID = newDrive.id
                newDriveID = newDrive.id
                
                statusString = "Gathering Case Contents"
                let contents = try await Drive.shared.getContents(of: aCase.label.folderID)
                let tuples : [(fileID:String, parentID:String, destinationID:String)] = contents.compactMap { content in
                    (fileID:content.id, parentID:content.parents?.first ?? "", destinationID:newDrive.id)
                }

                statusString = "Moving Case To New Shared Drive"
                _ = try await Drive.shared.move(tuples: tuples)
                
                statusString = "Deleting Old Case Folder"
                _ = try await Drive.shared.delete(ids: [aCase.label.folderID])
                
            } else {
                if aCase.label.folderTitle != editItem.label.folderTitle {
                    if aCase.file.driveId == aCase.label.folderID {
                        statusString = "Updating Drive Name"
                        _ = try await Drive.shared.sharedDrive(driveID: aCase.file.driveId ?? "", rename:editItem.label.folderTitle)
                    } else {
                        statusString = "Updating Folder Name"
                        _ = try await Drive.shared.rename(id: aCase.label.folderID, newName: editItem.label.folderTitle)
                    }
                }
            }
            
            if aCase.label.sheetTitle != editItem.label.sheetTitle {
                statusString = "Updating Case Spreadsheet"
                let renamedFile = GTLRDrive_File()
                renamedFile.name = editItem.label.sheetTitle
                _ = try await Drive.shared.update(id: aCase.file.id, with: renamedFile)
                aCase.file.name = editItem.label.sheetTitle
            }
            
        
            if editItem.label.status == .closed && aCase.label.closed != nil {
                editItem.label.closed = Date()
            } else if editItem.label.status != .closed {
                editItem.label.closed = nil
            }
            
            statusString = "Updating Case Label"
            _ = try await Drive.shared.label(modify: Case.DriveLabel.Label.id.rawValue, modifications: [editItem.label.labelModification], on: aCase.file.id)
           
            statusString = "Successfully Updated!"
            
            //Update local model
            aCase.label = editItem.label
            
            if let newDriveID {
                aCase.file.driveId = newDriveID
            }
        } catch {
            throw error
        }
    }
}
