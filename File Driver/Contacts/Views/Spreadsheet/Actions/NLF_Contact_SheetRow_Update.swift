//
//  NLF_Contact_SheetView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/4/25.
//

import SwiftUI



struct NLF_Contact_SheetRow_Update: View {
    var row : NLF_Contact.SheetRow
    @Binding var contact : NLF_Contact
    let customCategories : [String]
    let customLabels     : [String]
    init(_ row:NLF_Contact.SheetRow, from contact: Binding<NLF_Contact>, customCategories: [String] = [], customLabels: [String] = []) {
        self.row = row
        _editRow = State(initialValue: row)
        _contact = contact
        self.customCategories = customCategories
        self.customLabels = customLabels
    }

    @State private var editRow : NLF_Contact.SheetRow
    @State private var isEditing = false
    @State private var error : Error?
    @Environment(\.dismiss) var dismiss
    @Environment(NLF_ContactsController.self) var controller
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment:.center) {
                Text("Edit Contact Information")
                    .font(.title2)
                    .frame(minHeight:24)
                if isEditing {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.75)
                        .frame(width: 24, height: 24)
                        .padding(.trailing)
                } else if error != nil {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.red)
                        .padding(.trailing)

                }
            }
                .padding([.top, .horizontal])

            Form {
                Section {
                    LabeledContent("Category") {
                        NLF_Contact_SheetRow_Category(row: $editRow, customCategories: customCategories)
                    }
                    LabeledContent("Label") {
                        NLF_Contact_SheetRow_Label(row: $editRow, customLabels: customLabels)
                    }
                    LabeledContent("Value") {
                        NLF_Contact_SheetRow_Value(row: $editRow)
                    }
                } footer: {
                    if let error {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
                .formStyle(.grouped)
        }
            .disabled(isEditing)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Update") {
                        Task { await updateContactSheetRow() }
                    }
                        .disabled(!canEdit || isEditing)
                }
            }
    }
  
    var canEdit : Bool {
        guard editRow.category.isEmpty  == false else { return false }
        guard editRow.label.isEmpty     == false else { return false }
        guard editRow.value.isEmpty     == false else { return false }
        guard row != editRow        else { return false }
        return true
    }
    
    func updateContactSheetRow() async {
        do {
            isEditing = true
            try await controller.sheetRow(.update, row: editRow, from: contact)
            isEditing = false
            dismiss()
        } catch {
            isEditing = false
            self.error = error
        }
    }
}



