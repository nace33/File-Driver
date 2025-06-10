//
//  NLF_Form_Import.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/28/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive




struct NLF_Form_Import: View {
    @Environment(\.dismiss) var dismiss
    @Environment(NFL_FormController.self)  var controller
    @State private var isImporting = false
    @State private var error: Error?
    @State private var statusString = ""
    @State private var selected : GTLRDrive_File?
    
    @State private var label    = NLF_Form.Label.new()
    @AppStorage(BOF_Settings.Key.formsMasterIDKey.rawValue)  var formDriveID : String = "0AGhFu4ipV3y0Uk9PVA"
    
    var body: some View {
        VStackLoader(title: "Form Import", isLoading: $isImporting, status: $statusString, error: $error) {
            if formDriveID.isEmpty {
                NLF_Form_DriveID()
            } else {
                Form {
                    NLF_Form_StatusPicker(label:$label, showStatusColor:false)
                    NLF_Form_CategoryMenu(label: $label)

                }
                    .padding()
                Divider()
                Drive_Navigator(rootID: formDriveID, rootname: "Forms", onlyFolders: false, headerElements: [.pathBar]) { action, file in
                    switch action {
                        case .single, .push, .pop:
                            selected = file
                        default: break
                    }
                }
                    .frame(minHeight: 250)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .disabled(isImporting)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Import") { Task { await importForm() }}
                    .disabled(!canImport || isImporting)
            }
        }
    }
    
    
    private var canImport : Bool {
        guard error == nil                       else { return false }
        guard formDriveID.isEmpty       == false else { return false }
        guard label.category.isEmpty    == false else { return false }
        guard let selected else { return false }
        return selected.isFolder || selected.isGoogleType || selected.mime == .pdf
    }
}

//MARK: - Import Methods
fileprivate extension NLF_Form_Import {
    func importForm() async {
        do {
            guard let selected else { throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "No Selected Item To Import"]) }
            statusString  = "Getting Folder Info..."
            isImporting      = true
            
            let destinationFolder = try await controller.getDestinationFolder(label: label, driveID: formDriveID)
       
            if selected.isFolder {
                try await importFolder(folder:selected, to: destinationFolder)
            } else {
                try await importFile(selected, folder: destinationFolder)
            }
            
            isImporting = false
        } catch {
            isImporting = false
            self.error = error
            
        }
    }
    func importFile(_ file:GTLRDrive_File, folder:GTLRDrive_File) async throws {
        do {
            statusString  = "Importing \(file.title)..."
            
            let tempFile : GTLRDrive_File = if file.driveId == folder.driveId { //move
                try await Google_Drive.shared.move(file: file, to: folder)
            } else { //copy
                try await Google_Drive.shared.copy(fileID: file.id, rename: file.title, saveTo: folder.id)
//                print("Should remove drive label, if any, so it does not show up twice in the list")
            }
            
            statusString  = "Applying Form Label To \(file.title) ..."
            let importedFile = try await controller.update(file: tempFile, label:label.labelModification)
            
            if let newForm = NLF_Form(file: importedFile) {
                controller.add(newForm, select: false)
            }
        } catch {
            throw error
        }
    }
    func importFolder(folder:GTLRDrive_File, to destination:GTLRDrive_File) async throws {
        do {
            statusString  = "Fetching \(folder.title)..."
            let contents = try await Google_Drive.shared.getContents(of: folder.id)
            //possible contents will be empty, in which case method just returns and moves on.
            //do not throw error, becasuse this is a deep traversal and empty folders hsould be ignored during import
            for file in contents {
                if file.isFolder {
                    try await importFolder(folder:file, to: destination)
                }
                else {
                    try await importFile(file, folder: destination)
                }
            }
        } catch {
            throw error
        }
    }
}
