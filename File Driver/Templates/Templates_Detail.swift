//
//  TemplatesDetail.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/8/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive


struct Templates_Detail: View {
    @Environment(TemplatesDelegate.self) var delegate
    @AppStorage("File-Driver.TemplatesDetail.showLabel") var showLabel = false
    var body: some View {
        Group {
            if delegate.selectedIDs.count > 0 {
                DriveFileView(delegate.selectedFiles)
            } else {
                ContentUnavailableView("No Template Selected", systemImage:Sidebar_Item.Category.templates.iconString)
            }
        }
            .frame(minWidth:400, maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func canUpdateTemplate(_ editItem:Binding<Template>) -> Bool {
        guard !editItem.wrappedValue.label.filename.isEmpty    else {  return false }
        guard !editItem.wrappedValue.label.category.isEmpty else {  return false }
        return  editItem.wrappedValue.label != delegate.selectedTemplates.first!.label
    }

}

struct TemplateLabelDetail: View {
    let label : Template.Label
    let style : Style
    enum Style { case form, menu }
    init(_ label: Template.Label, style: Style ) {
        self.label = label
        self.style = style
    }
    var body: some View {
        switch style {
        case .form:
            Form {
                Section {
                    LabeledContent("Filename") { Text(label.filename).textSelection(.disabled)}
                    LabeledContent("Category") { Text(label.category.camelCaseToWords).textSelection(.disabled)}
                    LabeledContent("Sub-Category") { Text(label.subCategory.isEmpty ? "None" : label.subCategory).textSelection(.disabled)}
                    LabeledContent("Status") { Text(label.status.title).textSelection(.disabled)}
                    LabeledContent("Note") { Text(label.note.isEmpty ? "None" : label.note).textSelection(.disabled)}
                }
            }
                .formStyle(.grouped)
        case .menu:
            Text("\("Filename"): \(label.filename)")
            Text("\("Category"): \(label.category.camelCaseToWords)")
            if !label.subCategory.isEmpty {
                Text("\("Sub-Category"): \(label.subCategory)")
            }
            Text("\("Status"): \(label.status.title)")
            if !label.note.isEmpty {
                Text("\("Comment"): \(label.note)")
            }
        }

    }
    
}
#Preview {
    Templates_Detail()
}
