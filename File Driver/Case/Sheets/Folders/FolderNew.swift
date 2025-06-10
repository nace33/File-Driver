//
//  FolderNew.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/16/25.
//


import SwiftUI

//MARK: New Sheet
extension Case {
    struct FolderNew : View {
        var aCase : Case
        var created : (Folder) -> ()
        @State private var folderName : String = ""
        @State private var parentFolder : Folder? = nil
        @Environment(\.dismiss) var dismiss
        @State private var error : Case_Error? = nil
        @State private var isCreating = false

        var body: some View {
            Form {
                if isCreating {
                    HStack {
                        Spacer()
                        ProgressView("Creating Folder")
                        Spacer()
                    }
                }
                else if let error {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Button("Reset") { reset() }
                } else {
                    TextField("Name", text: $folderName, prompt:Text("Enter folder name..."))
                        .foregroundStyle(aCase.canCreate(folder:folderName, in: parentFolder) ? .primary : Color.red)
                    LabeledContent("Parent Directory") {
                        MenuButton(parentFolder?.name ?? "Root") {
                            Button("Root") { parentFolder = nil }
                            Divider()
                            ForEach(aCase.rootFolders) { root in
                                FolderMenu(aCase: aCase, folder: root) {
                                    parentFolder = $0
                                }
                            }
                        }.fixedSize()
                    }
                }
            }
                .formStyle(.grouped)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {create() }.disabled(!canCreate)
                    }
                }
            
        }
        
        
        
        var canCreate : Bool {
            !isCreating && error == nil && aCase.canCreate(folder:folderName, in: parentFolder)
        }
        func create()  {
            Task {
                do throws(Case_Error){
                    DispatchQueue.main.async {
                        isCreating = true
                    }
                    let newFolder =  try await aCase.create(folder: folderName, in: parentFolder)
                    DispatchQueue.main.async {
                        created(newFolder)
                        dismiss()
                        isCreating = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        isCreating = false
                        self.error = error
                    }
                }
            }
        }
        func reset() {
            folderName = ""; parentFolder = nil; self.error = nil
        }
    }
}
