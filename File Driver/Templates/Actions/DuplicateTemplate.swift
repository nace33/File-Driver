//
//  DuplicateTemplate.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct DuplicateTemplate<H:View>: View {

    let duplicateTemplate : Template
    let header : (() -> H)?
    init(_ duplicateTemplate:Template) where H == EmptyView {
        self.duplicateTemplate = duplicateTemplate
        self.header = nil
        let file = GTLRDrive_File()
        file.mimeType   = duplicateTemplate.file.mimeType
        file.name       = "Copy of " + duplicateTemplate.file.title
        file.identifier = duplicateTemplate.file.id
        var label = duplicateTemplate.label
        label.filename = "Copy of " + label.filename
        _template = State(initialValue:Template(file: file, label:label))
        _status   = State(initialValue:"Duplicate Template")
    }
    init(_ duplicateTemplate:Template, @ViewBuilder header: @escaping () -> H) {
        self.duplicateTemplate = duplicateTemplate
        self.header = header
        let file = GTLRDrive_File()
        file.mimeType   = duplicateTemplate.file.mimeType
        file.name       = "Copy of " + duplicateTemplate.file.title
        file.identifier = duplicateTemplate.file.id
        var label = duplicateTemplate.label
        label.filename = "Copy of " + label.filename
        _template = State(initialValue:Template(file: file, label:label))
        _status   = State(initialValue:"Duplicate Template")
    }
    
    @State private var status : String
    @State private var template : Template
    
    
    @Environment(TemplatesDelegate.self) var controller
    @Environment(\.dismiss) var dismiss
    @FocusState var isFocused : Bool
    
    var body: some View {
        EditForm(prompt: "Create", item: $template) {
            if let header { header() }
            else { Text(status).font(.title2) }
        } content: { editItem in
            TextField("Filename", text: editItem.label.filename, prompt: Text("Enter filename"))
                .onAppear() { isFocused = true }
                .focused($isFocused)
            
            TextField_Suggestions("Category", text: editItem.label.category, prompt:Text("Enter category"),  suggestions: controller.allCategories)
            
            TextField_Suggestions("Sub-Category", text: editItem.label.subCategory, prompt:Text("Optional"), suggestions: controller.subCategoriesOfCategory(editItem.wrappedValue.label.category))
            
            Picker("Status", selection: editItem.label.status) {
                ForEach(Template.DriveLabel.Status.allCases, id:\.self) { Text($0.title).tag($0)}
            }
            
            TextField("Note", text:editItem.label.note, prompt:Text("Must be less than 100 characters"), axis: .vertical)
        } canUpdate: { editItem in
            canCreateTemplate(editItem)

        } update: { editItem in
            editItem.wrappedValue.file.name = editItem.wrappedValue.label.filename
            _ = try await controller.create(editItem.wrappedValue,
                                            moveFile: nil,
                                            duplicateFile: duplicateTemplate.file.id,
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

