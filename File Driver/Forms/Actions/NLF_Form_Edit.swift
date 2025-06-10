//
//  NLF.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/28/25.
//

import SwiftUI

struct NLF_Form_Edit: View {
    var form : NLF_Form
    @State private var editableForm : NLF_Form
    @State private var filename: String
    init(form:NLF_Form) {
        self.form = form
        _editableForm = State(initialValue: form)
        _filename = State(initialValue: form.title)
    }
    @Environment(\.dismiss) var dismiss
    @Environment(NFL_FormController.self)  var controller
    @AppStorage(BOF_Settings.Key.formsMasterIDKey.rawValue)  var formDriveID : String = "0AGhFu4ipV3y0Uk9PVA"
    @State private var isSaving = false
    @State private var error : Error?
    @State private var statusString = ""
   
    var body: some View {
        VStackLoader(title: "Edit \(form.file.mime.title)", isLoading: $isSaving, status: $statusString, error: $error) {
            if formDriveID.isEmpty {
                NLF_Form_DriveID()
            } else {
                Form {
                    TextField("Filename", text: $filename)
                    NLF_Form_StatusPicker(label: $editableForm.label, showStatusColor: false)
                    NLF_Form_CategoryMenu(label: $editableForm.label)
                    NLF_Form_NoteField(label: $editableForm.label)
                }
                .formStyle(.grouped)
            }
        }
            .disabled(isSaving)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Update Form") { Task { await updateForm() }}
                        .disabled(!canSave || isSaving)
                }
            }
    }
    var canSave : Bool {
        guard filename.isEmpty          == false else { return false }
        guard editableForm.label.category.isEmpty     == false else { return false }
        return true
    }
    func updateForm() async {
        do {
            statusString  = "Updating..."
            isSaving      = true
           
            if form.title != filename {
                statusString  = "Renaming Form..."
                _ = try await Google_Drive.shared.rename(id: form.file.id, newName:filename)
                editableForm.file.name = filename
            }
            
   
            
            if editableForm.label.status != form.label.status ||
                editableForm.label.category != form.label.category ||
                editableForm.label.subCategory != form.label.subCategory ||
                editableForm.label.note != form.label.note {
                
                //Move - if necessary
                if editableForm.label.category != form.label.category || editableForm.label.subCategory != form.label.subCategory {
                    statusString  = "Moving Form ..."
                    let destinationFolder = try await controller.getDestinationFolder(label: editableForm.label, driveID: formDriveID)
                    
                    let newFile = try await Google_Drive.shared.move(file: form.file, to: destinationFolder)
                    form.file.parents = newFile.parents
                    form.file.identifier = newFile.identifier
                }
                
                //update label
                statusString  = "Updating Form..."
                _ = try await Google_Drive.shared.label(modify: NLF_Form.DriveLabel.id.rawValue, modifications: [editableForm.labelModification], on: form.file.id)
            }
            
            statusString  = "Done!"
//            isSaving = false, do not set because it makes UI Weird
            controller.update(editableForm, select: true)
            dismiss()
            
      
        } catch {
            isSaving = false
            self.error = error
        }
    }
}

