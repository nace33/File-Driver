//
//  EditContact_File.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/13/25.
//

import SwiftUI

struct EditContact_File: View {
    @Bindable var contact: Contact
    @Binding var file : Contact.File
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        EditForm(title:"Edit - \(contact.label.name)", item: $file) { editItem in
            TextField_Suggestions("Category", text:editItem.category, prompt:Text("Enter file category"), suggestions: contact.fileCategories)
 
            TextField("Filename", text: editItem.filename, prompt: Text("Enter filename"))
        }canUpdate: { editItem in
            canSendUpdate(editItem.wrappedValue)
        } update: { editItem in
            try await update(editItem.wrappedValue)
        }
    }
}

//MARK: - Actions
extension EditContact_File {
    func update(_ editedItem : Contact.File) async throws {
        do {
            if editedItem.category != file.category {
                try await contact.updateFileFolder(contactFile: editedItem)
            }
            if editedItem.filename != file.filename {
                try await contact.updateFilename(contactFile: editedItem)
            }
        } catch {
            throw error
        }
    }

    func canSendUpdate(_ editItem:Contact.File) -> Bool {
        guard editItem.category.isEmpty == false else { return false }
        guard editItem.filename.isEmpty == false else { return false }
        return true
    }

}
