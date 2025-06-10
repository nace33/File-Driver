//
//  NLF_Contact_View_Info_Category.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/4/25.
//

import SwiftUI

struct NLF_Contact_Info_Category: View {
    @Binding var contact : NLF_Contact
    @Binding var isEditing : Bool
    var category : String

    @AppStorage(BOF_Settings.Key.contactSheetKey.rawValue)   var sheet : NLF_Contact.Sheet = .contactInfo
    @State private var isUpdating = false
    @Environment(NLF_ContactsController.self) var controller

    var body: some View {
        GridRow {
            Text("")
            HStack {
                Button {Task { await addContactSheetRow()}} label: {
                    Text(category.uppercased())
//                    if isEditing { Image(systemName: "plus")}
                }
                    .buttonStyle(.link)
                    .bold()
                    .font(.caption)
//                    .disabled(!isEditing)
                    .contextMenu {
                        if !isEditing { Button("Add Info") { Task { await addContactSheetRow()}}}
                    }
                if isUpdating {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                }
            }
                .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)

        }
            .disabled(isUpdating)
    }
}


//MARK: - Actions
extension NLF_Contact_Info_Category {
    func addContactSheetRow() async {
        do {
            isUpdating = true
            let suggestion : String
            if let cat = NLF_Contact.SheetRow.Category(rawValue: category.wordsToCamelCase()),
                let sug = cat.labels.first, !sug.isEmpty {
                suggestion = sug
            } else {
                suggestion = "New Label"
            }
            let newRow = NLF_Contact.SheetRow.new(sheet: sheet, status: .editing, category:category, label:suggestion, value: "Change me!")
            try await controller.sheetRow(.add, row: newRow, from: contact)
        
            isUpdating = false
        } catch {
            isUpdating = false
        }
    }
}
