//
//  NLF_Contact_SheetRow_Delete.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/4/25.
//

import SwiftUI

struct NLF_Contact_SheetRow_Delete: View {
    @Binding var contact : NLF_Contact
    var row : NLF_Contact.SheetRow
    init(_ row: NLF_Contact.SheetRow, from contact: Binding<NLF_Contact>, ) {
        self.row = row
        _contact = contact
    }
    @State private var isDeleteing = false
    @State private var error : Error?
    @Environment(\.dismiss) var dismiss
    @Environment(NLF_ContactsController.self) var controller

    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment:.center) {
                Text("Confirm Deletion")
                    .font(.title2)
                    .frame(minHeight:24)
                
                if isDeleteing {
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
                    LabeledContent("Label") {
                        Text(row.label)
                    }
                    LabeledContent("Value") {
                        Text(row.value)
                    }
                } footer: {
                    HStack {
                        Spacer()
                        Text(error?.localizedDescription ?? "Warning: This deletion cannot be undone.")
                            .font(.caption)
                            .foregroundStyle(error == nil ? Color.primary : Color.red)
                    }
                }
            }
            .formStyle(.grouped)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) {
                        Task { await deleteContactSheetRow() }
                    }
                        .disabled(isDeleteing)
                }
            }
        }
    }
    
    var clearInsteadOfDelete : Bool {
        switch row.sheet {
        case .contactInfo:
            contact.info.count == 1
        case .files:
            contact.files.count == 1
        case .cases:
            contact.cases.count == 1
        }
    }
    func deleteContactSheetRow() async {
        do {
            isDeleteing = true
  
            try await controller.sheetRow(.delete, row: row, from: contact)

            dismiss()
        } catch {
            isDeleteing = false
            self.error = error
        }
    }
}

