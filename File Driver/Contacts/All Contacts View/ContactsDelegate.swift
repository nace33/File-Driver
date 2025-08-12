//
//  ContactsDelegate.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/10/25.
//

import SwiftUI
import UniformTypeIdentifiers
import GoogleAPIClientForREST_Drive

@Observable final class ContactsDelegate {
    static let shared: ContactsDelegate = { ContactsDelegate() }()
    var contacts : [Contact] = [] {
        didSet {
            loadContactGroups()
            loadFilterTokens()
        }
    }
    var groups     : [String] = []
    var selectedID : Contact.ID?
    var scrollToID : Contact.ID?
    var loader = VLoader_Item(isLoading: true)
    var filter = Filter()
}


//MARK: - Load
extension ContactsDelegate {
    func loadContacts() async {
        do {
            loader.start("Loading Contacts")
            contacts = try await Drive.shared.get(filesWithLabelID:Contact.DriveLabel.id.rawValue)
                                                    .compactMap { .init(file: $0)}
                                                    .sorted(by: {$0.label.nameReversed.ciCompare($1.label.nameReversed)})
        
            loader.stop()
        } catch {
            loader.stop(error)
        }
    }
    func loadContactGroups() {
        groups =   contacts.compactMap { $0.label.groupName}
                           .filter { !$0.isEmpty }
                           .unique()
                           .sorted(by: {$0.ciCompare($1)})
    }
    func loadFilterTokens() {
        let tokenA = Contact.DriveLabel.ClientStatus.allCases.compactMap { Filter.Token(prefix: .dollarSign, title: $0.title, rawValue: $0.rawValue)  }
        let tokenB = groups.compactMap { Filter.Token(prefix: .hashTag, title: $0, rawValue: $0)  }
        filter.allTokens = tokenA + tokenB
    }
}


//MARK: - Get
extension ContactsDelegate {
    var filteredContacts : Binding<[Contact]> {
        Binding {
            let shows :[Contact.Show] = UserDefaults.getEnums(forKey: BOF_Settings.Key.contactsShow.rawValue)
            let labelStatuses = shows.compactMap({$0.asStatus })

            return self.contacts.filter { contact in
                guard labelStatuses.contains(contact.label.status) else { return false }
                
                
                if !self.filter.string.isEmpty, !self.filter.hasTokenPrefix, !contact.label.name.ciContain(self.filter.string) { return false   }
                if !self.filter.tokens.isEmpty {
                    for token in self.filter.tokens {
                        if token.prefix == .dollarSign {
                            if contact.label.client.rawValue != token.rawValue { return false }
                        } else if token.prefix == .hashTag {
                            if contact.label.groupName != token.rawValue { return false }
                        }
                    }
                }
                return true
            }
        } set: { newValue in
            self.contacts = newValue
        }

    }
    subscript(id:Contact.ID?) -> Binding<Contact>? {
        Bindable(self).contacts.first(where: {$0.id == id})
    }
    func checkSelection() {
        guard let selectedID else { return }
        let currentIDs =  filteredContacts.wrappedValue.map(\.id)
        if currentIDs.contains(selectedID) {
            self.selectedID = nil
        }
    }
}


//MARK: - Update
extension ContactsDelegate {
    func update(_ contact: Binding<Contact>) async throws {
        do {
            //check to see if there is a new file to upload
            if let data = contact.wrappedValue.label.imageData {
                guard let folderID = contact.wrappedValue.file.parents?.first else { throw Contact_Error.custom("No folder ID found for contact \(contact.wrappedValue.label.name)")}
                var size = UserDefaults.standard.integer(forKey: BOF_Settings.Key.contactIconSizeKey.rawValue)
                if size == 0 { size = 96}
                #if os(macOS)
                guard let image = NSImage(data: data)?.copy(size: CGSize(width: size * 2, height: size * 2)) else { return }
                #else
                guard let image = UIImage(data: data)?.resized(to: CGSize(width: size * 2, height: size * 2)) else { return }
                #endif
                guard let png = image.PNGRepresentation else { return }

                let filename = Date().yyyymmdd + " Contact Icon" + " (\(contact.wrappedValue.label.name))"

                let iconFolder   = try await Drive.shared.get(folder: "Profile Icons", parentID: folderID, createIfNotFound: true)
                let uploadedFile = try await Drive.shared.upload(data:png, toParentID: iconFolder.id, name: filename, type:UTType.png.identifier)
            
                
                //Remove Cache
                if let cacheURL  = contact.wrappedValue.cacheURL {
                    try? FileManager.default.trashItem(at: cacheURL, resultingItemURL: nil)
                }
                
                //update new iconID
                contact.wrappedValue.label.iconID    = uploadedFile.id
                
                //cache saved data
                if let cacheURL  = contact.wrappedValue.cacheURL {
                    try? data.write(to: cacheURL)
                }
                contact.wrappedValue.label.imageData = nil
            }
      
            //status.wrappedValue = "Updating Drive Label ..."
            _  = try await Drive.shared.label(modify: Contact.DriveLabel.id.rawValue, modifications: [contact.wrappedValue.label.labelModification], on: contact.id)
            
            //fetch file with updated label
            var file = try await Drive.shared.get(fileID: contact.id, labelIDs: [Contact.DriveLabel.id.rawValue])
            
            //rename the file
            if file.title != contact.wrappedValue.label.nameReversed, let letter = contact.wrappedValue.label.nameReversed.first {
                
                //Get the parent folder
                guard let parentFolderID = file.parents?.first else { throw Contact_Error.custom("Contact Folder Not Found!")}
                let folder = try await Drive.shared.get(fileID:parentFolderID)
                
                let needToMoveFolder = !folder.title.ciHasPrefix(String(letter))
                
                //rename the folder
                let renamedFolder = try await Drive.shared.rename(id:folder.id, newName: contact.wrappedValue.label.nameReversed)
           
                if needToMoveFolder {
                    //Get the new letter folder
                    let defaultDrive    = try await getContactsDrive()
                    let letterFolder    = try await getLetterFolder(drive:defaultDrive, letter: String(letter))
                    _ = try await Drive.shared.move(file:renamedFolder, to:letterFolder)
                    //Move the
                }
                
                //rename the file
                _ = try await Drive.shared.rename(id:file.id, newName: contact.wrappedValue.label.nameReversed)
                file  = try await Drive.shared.get(fileID:contact.id, labelIDs: [Contact.DriveLabel.id.rawValue])
                
            }
            
//            contact.wrappedValue.file = file
//            if let label = Contact.Label.init(file: file) {
//                contact.wrappedValue.label = label
//            }
        } catch {
            throw error
        }
    }
    func update(_ contact:Binding<Contact>, info:Binding<Contact.Info>) async throws {
        do {
            info.wrappedValue.status = .editing
            _ = try await Sheets.shared.update(spreadsheetID: contact.wrappedValue.id, sheetRows: [info.wrappedValue])
            info.wrappedValue.status = .idle
        } catch {
            info.wrappedValue.status = .idle
            throw error
        }
    }
}



//MARK: - New
extension ContactsDelegate {
    func create(contact:Contact, select:Bool = true) async throws -> Contact {
        do {
            let label = contact.label
            guard label.firstName.isEmpty == false else {
                throw Contact_Error.custom("You must enter a first name")
            }
            
            guard let letter = label.nameReversed.first else {
                throw Contact_Error.invalidMethodParameters(#function)
            }

//            status.wrappedValue = "Getting Contacts Drive"
            let defaultDrive    = try await getContactsDrive()


//            status.wrappedValue = "Getting '\(String(letter))' Folder"
            let letterFolder    = try await getLetterFolder(drive:defaultDrive, letter: String(letter))
            
//            status.wrappedValue = "Creating Folder: '\(name)'"
            let contactFolder   = try await Drive.shared.create(folder:label.nameReversed, in: letterFolder.id, mustBeUnique: true)
            
//            status.wrappedValue = "Copying Contacts Template ..."
            
            //            status.wrappedValue = "Creating Contacts Spreadsheet"
            let newSpreadsheet = try await Drive.shared.create(fileType: .sheet, name: label.nameReversed, parentID: contactFolder.id, description: Contact.spreadsheetVersion)
                        
            //Installing Sheets
            let sheets = Contact.Sheet.allCases.compactMap { $0.gtlrSheet }
            try await Sheets.shared.initialize(id:newSpreadsheet.id, gtlrSheets:sheets)
            
//            self.statusString = "Applying Headers"
            _ = try await Sheets.shared.addHeaders(Contact.Sheet.allCases.compactMap(\.headerRow), in: newSpreadsheet.id)
            
//            self.statusString = "Formatting Spreadsheet"
            _ = try await Sheets.shared.format(wrap: .clip, vertical: .top, horizontal: .left, sheets:Contact.Sheet.allCases.map(\.intValue), in: newSpreadsheet.id)
            
//            status.wrappedValue = "Applying Drive Label ..."
            _  = try await Drive.shared.label(modify: Contact.DriveLabel.id.rawValue, modifications: [label.labelModification], on: newSpreadsheet.id)
           
            //fetch file with updated label
            let file = try await Drive.shared.get(fileID: newSpreadsheet.id, labelIDs: [Contact.DriveLabel.id.rawValue])
            
            //Rename the file
            let renamedFile = try await Drive.shared.rename(id:file.id, newName:label.nameReversed)
            
            //Do not return renamedFile, it does not have the drive label, instead update 'file' name and return
            file.name = renamedFile.name
//            status.wrappedValue = "Successfully Created Contact!"
         
            guard let newContact = Contact(file: file) else {
                throw Contact_Error.localIssueAskJimmyAbout(#function)
            }
            contacts.append(newContact)
            if select {
                selectedID = newContact.id
                scrollToID = newContact.id
            }
            return newContact
            
        } catch {
            throw error
        }
    }
    func getContactsDrive() async throws -> GTLRDrive_Drive {
        do {
            guard let id = UserDefaults.standard.string(forKey: BOF_Settings.Key.contactsDriveID.rawValue) else {
                throw Contact_Error.noDrive
            }
            return try await Drive.shared.sharedDrive(get: id)
        } catch {
            throw error
        }
    }
    func getLetterFolder(drive:GTLRDrive_Drive, letter:String) async throws -> GTLRDrive_File {
        do {
            guard !letter.isEmpty else { throw Contact_Error.invalidMethodParameters(#function) }
            let string = letter.count > 1 ? String(letter.first!) : letter
            return try await Drive.shared.get(folder: string.uppercased(), parentID: drive.id, createIfNotFound: true, caseInsensitive: true)
        } catch {
            throw error
        }
    }

    func copy(template:GTLRDrive_File, folder:GTLRDrive_File) async throws -> GTLRDrive_File{
        do {
            return try await Drive.shared.copy(fileID: template.id, rename: template.title, saveTo: folder.id)
        } catch {
            throw error
        }
    }
}
