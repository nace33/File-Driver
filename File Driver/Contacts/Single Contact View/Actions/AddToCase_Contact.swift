//
//  AddToCase_Contact.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import SwiftUI

struct AddToCase_Contact: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var contact: Contact
    
    @State private var selectedCase : Case?
    @State private var error: Error?
    
    var body: some View {
        Group {
            if let selectedCase {
                selectedCaseView(selectedCase)
            } else {
                SelectCase { aCase in
                    selectedCase = aCase
                    return false
                }
            }
        }
            .task(id:selectedCase?.id) { await addContactToSelectedCase() }
    }
    
    func addContactToSelectedCase() async {
        guard let selectedCase else { return }
        do {
            try await selectedCase.load(sheets: [.contacts])
            let centralIDs = selectedCase.contacts.map { $0.centralID}.unique()
            guard !centralIDs.contains(contact.id) else { throw NSError.quick("\(contact.label.name) is already in \(selectedCase.title)") }
            
            let caseContact = Case.Contact(id: UUID().uuidString, centralID: contact.id, folderID: nil, name: contact.label.name, role: nil, isClient: false, note: nil)
            try await Sheets.shared.append([caseContact], to: selectedCase.id)
            dismiss()
        } catch {
            self.error = error
        }
    }
    @ViewBuilder func selectedCaseView(_ aCase:Case) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if let error {
                    Text(error.localizedDescription)
                } else {
                    ProgressView("Adding to \(aCase.title)")
                }
                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight:350, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

