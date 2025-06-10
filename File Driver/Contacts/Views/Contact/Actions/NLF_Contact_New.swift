//
//  NLF_Contact_New.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//

import SwiftUI

struct NLF_Contact_New: View {
    var created:((NLF_Contact) -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    @Environment(NLF_ContactsController.self) var controller
    @State private var contact = NLF_Contact.new()
    @State private var isCreating = false
    @State private var status = ""
    @State private var error : Error?
    @State private var isClosed = false
    @AppStorage(BOF_Settings.Key.contactsDriveIDKey.rawValue)   var driveID : String = ""
    @AppStorage(BOF_Settings.Key.contactTemplateIDKey.rawValue) var templateID : String = ""

    var body: some View {
        VStack {
            if  !driveID.isEmpty && !templateID.isEmpty{
                VStackLoader(title:"Create Contact", isLoading: $isCreating, status: $status, error: $error) {
                    NLF_Contact_LabelView($contact,
                                          prompt: "Create Contact",
                                          fields: NLF_Contact_LabelView.Field.newFields) { newLabel in
                        await createContact(label: newLabel)
                    }
                }
            }
            else if driveID.isEmpty {
                Drive_Selector(rootTitle:"Select A Drive To Save Contacts In", mimeTypes: [.folder], canLoad: {_ in false},  select:  { selected in
                    driveID = selected.id
                })
            }
            else if templateID.isEmpty {
                Drive_Selector(rootTitle:"Select The Contacts Template", rootID:driveID, mimeTypes: [.sheet], select:  { selected in
                    templateID = selected.id
                })
            }
            else {
                Text("Houston, we have a problem.")
            }
        }
//        .frame(minHeight: 200)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(isCreating ? "Close" : "Cancel") { isClosed = true; dismiss() }
            }
        }

    }
    
    func createContact(label:NLF_Contact.Label) async -> Bool {
        do {
            guard let letter = label.lastName.isEmpty ? label.firstName.first : label.lastName.first else {
                throw NLF_ContactsController.Contact_Error.invalidMethodParameters(#function)
            }

            isCreating         = true
            status            = "Getting Contacts Drive"
            let defaultDrive  = try await controller.getContactsDrive()

            status            = "Getting Contacts Template"
            let template      = try await controller.getTemplate()

            status            = "Getting '\(String(letter))' Folder"
            let letterFolder  = try await controller.getLetterFolder(drive:defaultDrive, letter: String(letter))
            
            let name : String = label.lastName.isEmpty ? label.firstName : "\(label.lastName), \(label.firstName)"
            status            = "Creating Folder: '\(name)'"
            let contactFolder = try await Google_Drive.shared.create(folder: name, in: letterFolder.id, mustBeUnique: true)
            
            status            = "Copying Contacts Template ..."
            let copiedFile    = try await Google_Drive.shared.copy(fileID: template.id, rename: name, saveTo: contactFolder.id)
           
            status            = "Applying Drive Label ..."
            let newFile       = try await controller.update(file: copiedFile, label: label.labelModification)
            
            status            = "Successfully Created Contact!"
            try await Task.sleep(for: .seconds(1))
            
            isCreating = false
            guard let contact = NLF_Contact(file: newFile) else {
                throw NLF_ContactsController.Contact_Error.localIssueAskJimmyAbout(#function)
            }
            controller.add(contact, select:!isClosed )
            dismiss()
            
            created?(contact)
            return true
        } catch {
            isCreating = false
            status = ""
            self.error = error
            return false
        }
    }


}

#Preview {
    NLF_Contact_New()
}


