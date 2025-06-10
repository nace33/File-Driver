//
//  NLF_Form_New.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/28/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct NLF_Form_New: View {
    init(type: GTLRDrive_File.MimeType = .doc, name:String = "My new form") {
        _form = State(initialValue: .init(type: type, name: name))
        _filename = State(initialValue: name)
    }
    @AppStorage(BOF_Settings.Key.formsMasterIDKey.rawValue)  var formDriveID : String = "0AGhFu4ipV3y0Uk9PVA"
    @State private var form : NLF_Form
    @State private var filename : String
    @Environment(\.dismiss) var dismiss
    @State private var isSaving = false
    @State private var error : Error?
    @State private var statusString = ""
    @Environment(NFL_FormController.self)  var controller

    var body: some View {
        VStackLoader(title:"Create \(form.file.mime.title)", isLoading: $isSaving, status: $statusString, error: $error) {
            Form {
                TextField("Filename", text: $filename)
                NLF_Form_StatusPicker(label: $form.label, showStatusColor: false)
                NLF_Form_CategoryMenu(label:$form.label)
                NLF_Form_NoteField(label: $form.label)
            }
            .formStyle(.grouped)
        }
            .disabled(isSaving)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Create") { Task { await create() }}
                        .disabled(!canSave || isSaving)
                }
            }
    }
    var canSave : Bool {
        guard formDriveID.isEmpty         == false else { return false }
        guard filename.isEmpty            == false else { return false }
        guard form.label.category.isEmpty == false else { return false }
        return true
    }
    func create() async {
        do {
            isSaving      = true
            //Get Destination Folder
            statusString  = "Getting Folder Info..."
            let destinationFolder = try await controller.getDestinationFolder(label: form.label, driveID: formDriveID)
           
            //Create New File
            statusString  = "Creating \(form.file.mime.title): \(filename)..."
            let newFile   = try await controller.create(fileType: form.file.mime, filename: filename, folder: destinationFolder)
            
            //Apply Drive Label
            statusString  = "Updating \(filename)"
            let updatedFile = try await controller.update(file: newFile, label: form.labelModification)
            
            statusString  = "Done!"
            
            //update data model
            if let newForm = NLF_Form(file: updatedFile) {
                controller.add(newForm, select: true)
            } else {
                print("Google created form, but app failed to create form")
            }
            
            isSaving = false
            dismiss()
        } catch {
            isSaving = false
            self.error = error
        }
    }
}

