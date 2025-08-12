//
//  EditTemplate.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import SwiftUI

struct EditTemplate: View {
    @Binding var template : Template
    init(_ template:Binding<Template>) {
        _template      = template
        _originalLabel = .init(initialValue: template.wrappedValue.label)
    }
    @State private var status = "Edit Template Label"
    @Environment(TemplatesDelegate.self) var delegate
    @Environment(\.dismiss) var dismiss
    
    @State private var originalLabel : Template.Label
    @FocusState var isFocused : Bool

    
    var body: some View {
        EditForm(title: status, prompt: "Update", item: $template) { editItem in
            TextField("Filename", text: editItem.label.filename, prompt: Text("Enter filename"))
                .onAppear() { isFocused = true}
                .focused($isFocused)
            TextField_Suggestions("Category", text: editItem.label.category, prompt:Text("Enter category"), suggestions: delegate.allCategories)
            
            TextField_Suggestions("Sub-Category", text: editItem.label.subCategory, prompt:Text("Optional"), suggestions: delegate.subCategoriesOfCategory(editItem.wrappedValue.label.category))
            
            Picker("Status", selection: editItem.label.status) {
                ForEach(Template.DriveLabel.Status.allCases, id:\.self) { Text($0.title).tag($0)}
            }
            
            TextField("Note", text:editItem.label.note, prompt:Text("Must be less than 100 characters"), axis: .vertical)
            
        } canUpdate: { editItem in
            canUpdateTemplate(editItem)
        } update: { editItem in
            if editItem.wrappedValue.file.title != editItem.wrappedValue.label.filename {
                try await delegate.rename(template: editItem, newFilename: editItem.wrappedValue.label.filename ) { status = $0 }
            }
            if editItem.wrappedValue.label != originalLabel {
                try await delegate.updateDriveLabel(editItem) { status = $0 }
            }
            dismiss()
        }
    }
    
    func canUpdateTemplate(_ editItem:Binding<Template>) -> Bool {
        guard !editItem.wrappedValue.label.filename.isEmpty    else {  return false }
        guard !editItem.wrappedValue.label.category.isEmpty else {  return false }
        return  editItem.wrappedValue.label != originalLabel
    }
}

