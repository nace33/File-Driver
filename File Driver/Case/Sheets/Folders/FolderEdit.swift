//
//  Edit.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/16/25.
//

import SwiftUI

extension Case.Folder {
    struct Edit : View {
        init(_ folder: Case.Folder, in aCase: Case) {
            self.aCase = aCase
            self.folder = folder
            _folderName = State(initialValue: folder.name)
        }
        let aCase  : Case
        let folder : Case.Folder
        @State private var folderName = ""
        @Environment(\.dismiss) var dismiss
        @State private var error : Case_Error? = nil
        @State private var isUpdating = false
        
        var body: some View {
            Form {
                if isUpdating {
                    HStack {
                        Spacer()
                        ProgressView("Updating Folder")
                        Spacer()
                    }
                }
                else if let error {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Button("Reset") { reset() }
                } else {
                    TextField("Folder Name", text: $folderName)
                }
            }
                .formStyle(.grouped)
                .task(id:folder.id) { update() }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {save() }.disabled(!needsToSave)
                    }
                }
        }
        var nameIsValid : Bool {
            guard folderName != folder.name else { return true }
            guard folderName.isEmpty == false else { return false }
            return aCase.canCreate(folder: folderName, in: aCase.getFolder(id: folder.parentID))
        }
        var needsToSave : Bool {
          folderName != folder.name && nameIsValid && !isUpdating
        }
        func update() {
            self.folderName = folder.name
        }
        func save() {
            print(#function)
        }
        func reset() {
            folderName = folder.name
            self.error = nil
        }
    }
    
    
}
