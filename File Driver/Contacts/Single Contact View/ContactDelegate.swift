//
//  ContactDelegate.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import SwiftUI

@Observable public final class ContactDelegate {
    var contact : Contact = Contact.new()
    let loader = VLoader_Item()
}


//MARK: - Load
public extension ContactDelegate {
    func load(_ sheets:[Contact.Sheet]) async {
        loader.start("Loading")
        
        do {
            let start = CFAbsoluteTimeGetCurrent()
            
            let spreadsheet = try await Sheets.shared.getSpreadsheet(contact.id, ranges: sheets.compactMap(\.rawValue))
            for range in sheets {
                guard let rowData = spreadsheet.rowData(range: range.rawValue, dropHeader: true) else { continue }
                switch range {
                case .info:
                    contact.infos = rowData.compactMap { Contact.Info(rowData: $0)}
                case .files:
                    contact.files = rowData.compactMap { Contact.File(rowData: $0)}
                }
            }
            
            loader.stop()
            let diff = CFAbsoluteTimeGetCurrent() - start
            print("Loading \(contact.label.name) Data Took: \(diff) seconds")
        } catch {
            print("Error \(#function)")
            loader.stop(error)
        }
    }
}


//MARK: - Info Sheet
public extension ContactDelegate {
    func resetOtherEditingInfos() {
        for (index,element) in contact.infos.enumerated() {
            if element.status == .editing {
                contact.infos[index].status = .idle
            }
        }
    }
    func createInfo(category:String) async throws {
        do {
            let label = Contact.Info.Category(rawValue: category.wordsToCamelCase())?.labels.first ?? "Home"
            let newContactInfo = Contact.Info(id: UUID().uuidString, idDate: Date.idString, category: category, label:label, value: "Change Me!", status: .creating)
            try await create(newContactInfo)
        } catch {
            throw error
        }
    }
    func create(_ newContactInfo:Contact.Info) async throws {
        do {
            withAnimation {
                contact.infos.append(newContactInfo)
            }
            _ = try await Sheets.shared.append([newContactInfo], to: contact.id)

            resetOtherEditingInfos()
            if let index = contact.infos.firstIndex(where: {$0.id == newContactInfo.id}) {
                if contact.infos[index].status == .creating {
                    contact.infos[index].status = .editing
                }
            }
        } catch {
            throw error
        }
    }
    func update(_ info:Binding<Contact.Info> ) async throws {
        Task {
            do {
                info.wrappedValue.status = .updating
                _ = try await Sheets.shared.update(spreadsheetID: contact.id, sheetRows: [info.wrappedValue])
                info.wrappedValue.status = .idle
            } catch {
                info.wrappedValue.status = .idle
                throw error
            }
        }
    }
    func delete(_ info:Binding<Contact.Info> ) async throws {
        Task {
            do {
                info.wrappedValue.status = .deleting
                if contact.infos.count == 1 {
                    _ = try await Google_Sheets.shared.clear(rowID:info.id, sheetName: Contact.Sheet.info.rawValue, spreadsheetID: contact.id)
                } else {
                    _ = try await Google_Sheets.shared.delete(rowID:info.id, sheetName:Contact.Sheet.info.rawValue, spreadsheetID: contact.id)
                }
                withAnimation {
                    _ = contact.infos.remove(id: info.id)
                }
            } catch {
                info.wrappedValue.status = .idle
                throw error
            }
        }
    }
}


//MARK: - Files Sheet
public extension ContactDelegate {
    func create(_ newFile:Binding<Contact.File>) async throws {
        do {
            guard !newFile.wrappedValue.category.isEmpty else { throw Contact_Error.custom("No category entered")}
            guard !newFile.wrappedValue.filename.isEmpty else { throw Contact_Error.custom("No filename entered")}
            
            guard let parentID =  contact.file.parents?.first else { throw Contact_Error.custom("No contact folder found.")}
            
//            status = "Getting Folder..."
            let folder   = try await Drive.shared.get(folder: newFile.wrappedValue.category, parentID: parentID, createIfNotFound: true, caseInsensitive: true)
//            status = "Copying File..."
            let copyFile = try await Drive.shared.copy(fileID: newFile.wrappedValue.fileID, rename: newFile.wrappedValue.filename, saveTo: folder.id)
            
            //Update local Model
            newFile.wrappedValue.fileID   = copyFile.id

            //Update Google Sheet
            _ = try await Sheets.shared.append([newFile.wrappedValue], to: contact.id)
            
            withAnimation {
                contact.files.append(newFile.wrappedValue)
            }
        } catch {
            throw error
        }
    }
    func create(_ newFile:Binding<Contact.File>, upload:Contact.File.LocalURL) async throws {
        do {
            guard let parentFolderID = contact.file.parents?.first else { throw NSError.quick("No Parent Folder")}
            guard !newFile.wrappedValue.category.isEmpty else { throw NSError.quick("No File Category")}
            guard !newFile.wrappedValue.filename.isEmpty else { throw NSError.quick("No Filename")}
            
            //Get Save Folder
            let categoryFolder = try await Drive.shared.get(folder:newFile.wrappedValue.category, parentID: parentFolderID, createIfNotFound: true, caseInsensitive: true)
            
            //Upload
            let uploadedFile = try await Drive.shared.upload(url: upload.url, filename: newFile.wrappedValue.filename, to: categoryFolder.id)
          
            //Update local Model
            newFile.wrappedValue.fileID   = uploadedFile.id
            newFile.wrappedValue.filename = uploadedFile.title
            newFile.wrappedValue.mimeType = uploadedFile.mime.rawValue
            
            //Update Google Sheet
            _ = try await Sheets.shared.append([newFile.wrappedValue], to: contact.id)
            
            withAnimation {
                contact.files.append(newFile.wrappedValue)
            }
        } catch {
            throw error
        }
    }
    func updateFileFolder(contactFile:Contact.File) async throws {
        do {
            guard let parentID = contact.file.parents?.first else { throw Contact_Error.custom("Parent ID not found")}
            let folder = try await Drive.shared.get(folder: contactFile.category, parentID: parentID, createIfNotFound: true, caseInsensitive: true)
            let googleFile   = try await Drive.shared.get(fileID: contactFile.fileID)
            guard let fileParentID = googleFile.parents?.first else { throw Contact_Error.custom("No parent ID found for \(contactFile.filename)")}
            _ = try await Drive.shared.move(fileID:contactFile.fileID, from:fileParentID, to: folder.id)
        } catch {
            throw error
        }
    }
    func updateFilename(contactFile:Contact.File) async throws {
        do {
            _ = try await Drive.shared.rename(id: contactFile.fileID, newName: contactFile.filename)
            _ = try await Sheets.shared.update(spreadsheetID: contact.id, sheetRows: [contactFile])
        } catch {
            throw error
        }
    }
    func delete(_ file:Binding<Contact.File>, trash:Bool) async throws {
        do {
            file.wrappedValue.status = trash ? .trashing : .removing
            if trash {
                _ = try await Drive.shared.delete(ids: [file.wrappedValue.fileID])
            }
            if contact.files.count == 1 {
                _ = try await Google_Sheets.shared.clear(rowID:file.id, sheetName: Contact.Sheet.files.rawValue, spreadsheetID: contact.id)
            } else {
                _ = try await Google_Sheets.shared.delete(rowID:file.id, sheetName:Contact.Sheet.files.rawValue, spreadsheetID: contact.id)
            }
            withAnimation {
                _ = contact.files.remove(id: file.wrappedValue.id)
            }
        } catch {
            file.wrappedValue.status = .idle
            throw error
        }
    }
}


//MARK: - General Actions
public extension ContactDelegate {
    func addTo(_ aCase: Case) async throws {
        //Step Create Sheets rows for Case.Contact and Case.ContactsData
        //Add to Case Spreadsheet
    }
}
