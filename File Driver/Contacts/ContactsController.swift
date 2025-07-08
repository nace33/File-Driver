//
//  Contacts.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/11/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import UniformTypeIdentifiers

@Observable
final class ContactsController {
    static let shared: ContactsController = { ContactsController() }()
    var contacts : [Contact] = [] {
        didSet {
            loadContactGroups()
            loadFilterTokens()
        }
    }
    var groups     : [String] = []
    var selectedID : Contact.ID?
    var scrollToID : Contact.ID?
    var isLoading = false
    var loadingError : Error?
    
    var filter = Filter()
}


//MARK: - Computed Properties
extension ContactsController {
    func index(of id:Contact.ID) -> Int? {
        contacts.firstIndex(where: {$0.id == id})
    }
    func index(of contact:Contact) -> Int? {
        contacts.firstIndex(where: {$0.id == contact.id})
    }
    subscript(id:Contact.ID?) -> Contact? {
        guard let id, let index = index(of: id) else { return nil }
        return contacts[index]
    }
    var selectedIndex : Int? {
        guard let selectedID, let index = index(of: selectedID) else { return nil }
        return index
    }
    var selected   : Contact? {
        guard let selectedIndex else { return nil }
        return contacts[selectedIndex]
    }
}


//MARK: - LOAD
extension ContactsController {
    func loadContacts() async {
        do {
            isLoading = true
            contacts = try await Drive.shared.get(filesWithLabelID:Contact.DriveLabel.id.rawValue)
                                                    .compactMap { .init(file: $0)}
                                                    .sorted(by: {$0.label.nameReversed.ciCompare($1.label.nameReversed)})
        
            isLoading = false
        } catch {
            isLoading = false
            loadingError = error
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



//MARK: - Update
extension ContactsController {
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
}



//MARK: - New
extension ContactsController {
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

//            status.wrappedValue = "Getting Contacts Template"
            let template        = try await getTemplate()

//            status.wrappedValue = "Getting '\(String(letter))' Folder"
            let letterFolder    = try await getLetterFolder(drive:defaultDrive, letter: String(letter))
            
//            status.wrappedValue = "Creating Folder: '\(name)'"
            let contactFolder   = try await Drive.shared.create(folder:label.nameReversed, in: letterFolder.id, mustBeUnique: true)
            
//            status.wrappedValue = "Copying Contacts Template ..."
            let copiedFile      = try await Drive.shared.copy(fileID: template.id, rename: label.nameReversed, saveTo: contactFolder.id)
           
//            status.wrappedValue = "Applying Drive Label ..."
            _  = try await Drive.shared.label(modify: Contact.DriveLabel.id.rawValue, modifications: [label.labelModification], on: copiedFile.id)
           
            //fetch file with updated label
            let file = try await Drive.shared.get(fileID: copiedFile.id, labelIDs: [Contact.DriveLabel.id.rawValue])
            
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
            guard let id = UserDefaults.standard.string(forKey: BOF_Settings.Key.contactsDriveIDKey.rawValue) else {
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
    func getTemplate() async throws -> GTLRDrive_File {
        do {
            guard let id = UserDefaults.standard.string(forKey: BOF_Settings.Key.contactTemplateIDKey.rawValue) else {
                throw Contact_Error.noTemplate
            }
            return try await Drive.shared.get(fileID: id)
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
