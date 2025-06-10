//
//  NLF_Contact_SheetView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/4/25.
//

import SwiftUI



struct NLF_Contact_SheetRow_Add: View {
    
    @Binding var contact : NLF_Contact
    let customCategories : [String]
    let customLabels     : [String]
    init(_ contact: Binding<NLF_Contact>, customCategories: [String] = [], customLabels: [String] = []) {
        _contact = contact
        self.customCategories = customCategories
        self.customLabels = customLabels
    }

    @State private var row : NLF_Contact.SheetRow = .new(sheet: .contactInfo, status: .editing)
    @State private var isCreating = false
    @State private var error : Error?
    @Environment(\.dismiss) var dismiss
    @Environment(NLF_ContactsController.self) var controller

    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment:.center) {
                Text("New Contact Information")
                    .font(.title2)
                    .frame(minHeight:24)
                if isCreating {
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
                        NLF_Contact_SheetRow_Category(row: $row, customCategories: customCategories)
                    }
                    LabeledContent("Label") {
                        NLF_Contact_SheetRow_Label(row: $row, customLabels: customLabels)
                    }
                    LabeledContent("Value") {
                        NLF_Contact_SheetRow_Value(row: $row)
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
            .disabled(isCreating)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss()  }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Create") {  Task { await addContactSheetRow() } }
                        .disabled(!canCreate || isCreating)
                }
            }
    }
  
    var canCreate : Bool {
        guard !row.category.isEmpty else { return false }
        guard !row.label.isEmpty    else { return false }
        guard !row.value.isEmpty    else { return false }
        return true
    }

    func addContactSheetRow() async {
        do {
            isCreating = true
            try await controller.sheetRow(.add, row: row, from: contact)

            isCreating = false
            dismiss()
        } catch {
            isCreating = false
            self.error = error
        }
    }
}




