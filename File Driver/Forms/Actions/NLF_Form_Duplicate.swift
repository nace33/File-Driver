//
//  NLF_Form_Duplicate.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/28/25.
//

import SwiftUI

struct NLF_Form_Duplicate: View {
    var form : NLF_Form
    @Environment(\.dismiss) var dismiss
    @Environment(NFL_FormController.self)  var controller
    @State private var isDuplicating = false
    @State private var error : Error?
    @State private var statusString = ""
    
    var body: some View {
        VStackLoader(title: "Duplicating Form...", isLoading: $isDuplicating, status: $statusString, error: $error) {
            HStack {
                ProgressView(statusString)
                    .font(.headline)
            }
                .padding()
        }
            .task(id:form.id) {
                await duplicate()
            }
    }
    
    func duplicate() async {
        do {
            guard let folderID = form.file.parents?.first else { throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "No folder to save to"])}
            isDuplicating = true
            statusString = "Copying Existing Form..."
            let filename = "\(form.title) copy"
            let file = try await Google_Drive.shared.copy(fileID: form.file.id, rename: filename, saveTo: folderID)
            var newForm = NLF_Form(type: form.file.mime, name: filename)
            newForm.file.name = file.name
            newForm.file.identifier = file.id
            newForm.file.mimeType = file.mime.rawValue
            newForm.file.parents = file.parents
            
            newForm.label.category = form.label.category
            newForm.label.subCategory = form.label.subCategory
            newForm.label.status = .drafting
            newForm.label.timesUsed = 0
            newForm.label.lastUsed = Date()
            newForm.label.lastUsedBy = Google.shared.user?.profile?.email ?? "Unknown User"
            statusString = "Appling Form Label..."
            _ = try await Google_Drive.shared.label(modify: NLF_Form.DriveLabel.id.rawValue, modifications: [newForm.labelModification], on: newForm.id)
            statusString = "Done!"
            controller.add(newForm, select: true)
            isDuplicating = false
            dismiss()
        } catch {
            isDuplicating = false
            self.error = error
        }
    }
}

