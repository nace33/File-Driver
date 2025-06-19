//
//  NewTemplate.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
struct NewTemplate: View {
    
    init(from mimeType:GTLRDrive_File.MimeType) {
        _newTemplate = State(initialValue: Template.init(type:mimeType, name: ""))
    }
    
    @State private var status : String = "New Template"
    @Environment(TemplatesController.self) var controller
    @Environment(\.dismiss) var dismiss
    @State private var newTemplate : Template
    @FocusState var isFocused : Bool

    var body: some View {
        EditForm(title:status, prompt: "Create", item: $newTemplate) { editItem in
            TextField("Filename", text: editItem.label.filename, prompt: Text("Enter filename"))
                .onAppear() { isFocused = true}
                .focused($isFocused)
            TextField_Suggestions("Category", text: editItem.label.category, prompt:Text("Enter category"),  suggestions: controller.allCategories)
            
            TextField_Suggestions("Sub-Category", text: editItem.label.subCategory, prompt:Text("Optional"),  suggestions: controller.subCategoriesOfCategory(editItem.wrappedValue.label.category))
            
            Picker("Status", selection: editItem.label.status) {
                ForEach(Template.DriveLabel.Status.allCases, id:\.self) { Text($0.title).tag($0)}
            }
            
            TextField("Note", text:editItem.label.note, prompt:Text("Must be less than 100 characters"), axis: .vertical)
            
        } canUpdate: { editItem in
            canCreateTemplate(editItem)
        } update: { editItem in
            editItem.wrappedValue.file.name = editItem.wrappedValue.label.filename
            _ = try await controller.create(editItem.wrappedValue,
                                            duplicateFile: nil,
                                            progress: { string in
                                                status = string
                                            })
            dismiss()
        }
    }
    
    func canCreateTemplate(_ editItem:Binding<Template>) -> Bool {
        guard !editItem.wrappedValue.label.filename.isEmpty else  { return false }
        guard !editItem.wrappedValue.label.category.isEmpty else { return false }
        return true
    }
}

#Preview {
    NewTemplate(from: .doc)
        .environment(TemplatesController.shared)
}
