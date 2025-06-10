//
//  NLF_ContactsController.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive


@Observable public final
class NLF_ContactsController {
    var contacts        : [NLF_Contact] = []
    var groups          : [String] = []
    var error           : Error?
    var isLoading       = false
    var loadStatus      = ""
    
    var selection      : Set<NLF_Contact.ID> = []
    var filter         = Filter()
    
}


//MARK: -Load
public extension NLF_ContactsController {
    func load() async {
        isLoading = true
        do {
            loadStatus = "Loading Contacts..."
            let files = try await Google_Drive.shared.get(filesWithLabelID: NLF_Contact.DriveLabel.id.rawValue)
//            for file in files {
//                print("\(file.title): \(String(describing: file.modifiedTime?.date))")
//            }
            contacts = files.compactMap { .init(file: $0)}
                            .sorted(by: {$0.name.ciCompare($1.name)})
            
            loadGroups()
            loadTokens()
            
            loadStatus = ""
            isLoading = false
        }
        catch {
            loadStatus = ""
            isLoading = false
            self.error = error
        }
    }
    func loadGroups() {
        groups   = contacts.compactMap { $0.label.groupName}
                           .unique()
                           .sorted(by:  { $0.ciCompare($1)})
    }
    func loadTokens() {
        filter.allTokens = NLF_Contact.DriveLabel.ClientStatus.allCases.compactMap { Filter.Token(prefix: .hashTag, title: $0.title, rawValue: $0.rawValue)}

    }
    func add(_ contact:NLF_Contact, select:Bool) {
        guard index(of: contact) == nil else { return }
        contacts.append(contact)
        
        contacts.sort(by: {$0.name.ciCompare($1.name)})
        loadTokens()
        if select {
            self.selection = [contact.id]
        }
    }

}

//MARK: -Selection
public extension NLF_ContactsController {
    func index(of contactID: NLF_Contact.ID) -> Int? {
        contacts.firstIndex(where: {contactID == $0.id})
    }
    func index(of contact: NLF_Contact) -> Int? {
        index(of: contact.id)
    }
    var selectedContacts : [NLF_Contact] {
        selection.compactMap { id in
            guard let index = index(of: id) else { return nil }
            return contacts[index]
        }
            .sorted(by: {$0.name.ciCompare($1.name)})
    }
}


//MARK: -Filter
public extension NLF_ContactsController {
    func filteredContacts(showVisible:Bool, showHidden:Bool, showPurged:Bool) -> [NLF_Contact] {
        contacts.filter { contact in
           if !showVisible, contact.label.status == .active { return false }
           if !showHidden,  contact.label.status == .hidden  { return false }
           if !showPurged,  contact.label.status == .purge   { return false }

           if !filter.string.isEmpty, !filter.hasTokenPrefix, !contact.name.ciContain(filter.string) { return false   }
           if !filter.tokens.isEmpty {
               for token in filter.tokens {
                   if contact.label.client.rawValue != token.rawValue { return false }
               }
           }
           return true
       }
   }
}


//MARK: -Contact Drive Methods
public extension NLF_ContactsController {
    func getContactsDrive() async throws -> GTLRDrive_Drive {
        do {
            guard let id = UserDefaults.standard.string(forKey: BOF_Settings.Key.contactsDriveIDKey.rawValue) else {
                throw Contact_Error.noDrive
            }
            return try await Google_Drive.shared.sharedDrive(get: id)
        } catch {
            throw error
        }
    }
    func getLetterFolder(drive:GTLRDrive_Drive, letter:String) async throws -> GTLRDrive_File {
        do {
            guard !letter.isEmpty else { throw Contact_Error.invalidMethodParameters(#function) }
            let string = letter.count > 1 ? String(letter.first!) : letter
           return try await Google_Drive.shared.get(folder: string, parentID: drive.id, createIfNotFound: true, caseInsensitive: true)
        } catch {
            throw error
        }
    }
    func getTemplate() async throws -> GTLRDrive_File {
        do {
            guard let id = UserDefaults.standard.string(forKey: BOF_Settings.Key.contactTemplateIDKey.rawValue) else {
                throw Contact_Error.noTemplate
            }
            return try await Google_Drive.shared.get(fileID: id)
        } catch {
            throw error
        }
    }
    func copy(template:GTLRDrive_File, folder:GTLRDrive_File) async throws -> GTLRDrive_File{
        do {
            return try await Google_Drive.shared.copy(fileID: template.id, rename: template.title, saveTo: folder.id)
        } catch {
            throw error
        }
    }
    func update(file:GTLRDrive_File, label:GTLRDrive_LabelModification) async throws -> GTLRDrive_File {
        do {
            _  = try await Google_Drive.shared.label(modify: NLF_Contact.DriveLabel.id.rawValue, modifications: [label], on: file.id)
            //fetch file with updated label
            let file = try await Google_Drive.shared.get(fileID: file.id, labelIDs: [NLF_Contact.DriveLabel.id.rawValue])
            if let index = contacts.firstIndex(where: { $0.id == file.id }), let c = NLF_Contact(file: file) {
                contacts[index].label = c.label
                
                if contacts[index].label.nameReversed != c.file.title {
                    _ = try await Google_Drive.shared.rename(id:file.id, newName: c.label.nameReversed)
                    contacts[index].file.name = c.label.nameReversed
                }
            }
            loadGroups()
            loadTokens()
            return file
        }
        catch {
            throw error
        }
    }

}


//MARK: -Spreadsheet Rows
public extension NLF_ContactsController {
    //Should only be called from methods with signature:
    ///addContactSheetRow
    ///updateContactSheetRow
    ///deleteContactSheetRow
    enum Action { case add, update, delete }
    func sheetRow(_ action:Action, row:NLF_Contact.SheetRow, from contact:NLF_Contact) async throws {
        do {
            switch action {
            case .add:
                try await sheetRowAdd(row, contact)
            case .update:
                try await sheetRowUpdate(row, contact)
            case .delete:
                try await sheetRowDelete(row, contact)
            }
        } catch {
            throw error
        }
    }
    fileprivate func sheetRowAdd(_ row:NLF_Contact.SheetRow, _ contact:NLF_Contact) async throws {
        do {
            _ = try await Google_Sheets.shared.append(spreadsheetID: contact.id, sheetName: row.sheet.rawValue, row: row.strings)
            guard  let index = index(of: contact) else { throw Contact_Error.contactNotFound(contact.name)  }
            contacts[index].add(row)
        } catch {
            throw error
        }
    }
    fileprivate func sheetRowUpdate(_ row:NLF_Contact.SheetRow, _ contact:NLF_Contact) async throws {
        do {
            guard  let index = index(of: contact) else { throw Contact_Error.contactNotFound(contact.name)  }
            _ = try await Google_Sheets.shared.update(values: row.strings, rowID: row.id, sheetName: row.sheet.rawValue, spreadsheetID: contact.id)
            contacts[index].update(row)
        } catch {
            throw error
        }
    }
    fileprivate func sheetRowDelete(_ row:NLF_Contact.SheetRow, _ contact:NLF_Contact) async throws {
        do {
            guard  let index = index(of: contact) else { throw Contact_Error.contactNotFound(contact.name)  }
            if contact.info.count == 1 {
                _ = try await Google_Sheets.shared.clear(rowID: row.id, sheetName: row.sheet.rawValue, spreadsheetID: contact.id)
            } else {
                _ = try await Google_Sheets.shared.delete(rowID: row.id, sheetName: row.sheet.rawValue, spreadsheetID: contact.id)
            }
            contacts[index].remove(row)
        } catch {
            throw error
        }
    }
}

//MARK: -Error
public extension NLF_ContactsController {
    enum Contact_Error : Error {
        case noDrive
        case noTemplate
        case invalidMethodParameters(String)
        case localIssueAskJimmyAbout(String)
        case contactNotFound(String)
        var localizedDescription: String {
            switch self {
            case .noDrive:
                "No Drive"
            case .noTemplate:
                "No Template"
            case .invalidMethodParameters(let function):
                "Invalid method parameters: \(function)"
            case .localIssueAskJimmyAbout(let function):
                "Local issue. Ask Jimmy about: \(function)"
            case .contactNotFound(let name):
                "Contact not found: \(name)"
            }
        }
    }
}
