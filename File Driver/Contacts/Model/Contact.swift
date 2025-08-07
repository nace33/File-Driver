//
//  Contact-.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/12/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

@Observable
public
final class Contact {
    var file        : GTLRDrive_File
    var label       : Contact.Label
    
    init(file: GTLRDrive_File, label: Contact.Label) {
        self.file = file
        self.label = label
    }
    
    var isLoading = false
    var error  : Error?
    
    //INFO
    var infos : [Contact.Info] = [] {
        didSet {
            loadCategories(.info)
        }
    }
    var infoCategories : [String] = []
    
    //FILES
    var files : [Contact.File] = [] {
        didSet {
            loadCategories(.files)
        }
    }
    var fileCategories : [String] = []
    
    var cases : [Contact.Case] = [] {
        didSet {
            loadCategories(.cases)
        }
    }
}

//MARK: - Protocols
extension Contact : Equatable, Hashable, Identifiable {
    public var id   : String { file.id }
    public static func == (lhs: Contact, rhs: Contact) -> Bool {   lhs.id == rhs.id && lhs.label == rhs.label }
    public func hash(into hasher: inout Hasher) {  hasher.combine(id)  }
}


//MARK: - Convenience
public extension Contact {
    convenience init?(file: GTLRDrive_File) {
        guard let label = Contact.Label(file: file) else { return nil }
        self.init(file: file, label: label)
    }
    static func new(status:DriveLabel.Status = .active,
                    client:DriveLabel.ClientStatus = .notAClient,
                    firstName:String = "",
                    lastName:String  = "",
                    groupName:String = "",
                    iconID:String    = "",
                    timesUsed:Int    = 0) -> Contact {
    
        let file = GTLRDrive_File()
        file.name       = "New File"
        file.identifier = UUID().uuidString
        let label       = Contact.Label(status: status,
                                        client:client,
                                        firstName: firstName,
                                        lastName: lastName,
                                        groupName: groupName,
                                        iconID: iconID)
        return .init(file:file, label:label)
    }
    static func sample() -> Contact {
        .new(firstName: "Frodo", lastName:"Baggins", groupName: "Lord of the Rings")
    }
    

}


//MARK: - Sheets
public extension Contact {
    enum Sheet :String, CaseIterable {
        case  info, files, cases

        var title : String {
            rawValue.capitalized
        }
    }
    enum Sort : String, CaseIterable {
        case firstName, lastName, client, group, status
        var title : String { rawValue.camelCaseToWords }
    }
}

//MARK: - Load
public extension Contact {
    func load(_ sheets:[Sheet]) async throws {
        do {
            self.error = nil
            isLoading = true
            print("Convert to Sheets")
            try await Task.sleep(for: .seconds(2))
            /*
            let results = try await Google_Sheets.shared.getValues(spreadsheetID:id, ranges: sheets.map({$0.rawValue}))
            for result in results {
                if result.range.contains(Contact.Sheet.info.title) {
                    infos = result.values.compactMap { .init(row: $0) }
                                         .sorted(by: {$0.id.ciCompare($1.id)})
                } else if result.range.contains(Contact.Sheet.files.title) {
                    files = result.values.compactMap { .init(row: $0)}
                                  .sorted(by: {$0.id.ciCompare($1.id)})
                } else if result.range.contains(Contact.Sheet.cases.title) {
                    cases = result.values.compactMap { .init(row: $0)}
                                  .sorted(by: {$0.id.ciCompare($1.id)})
                }
                else {
                    print("Unknown Range \(result.range)")
                }
             
            }
             */
            isLoading = false
        } catch {
            isLoading = false
            throw error
        }
    }

    func loadCategories(_ sheet:Sheet) {
        switch sheet {
        case .info:
            infoCategories = infos.compactMap({$0.category}).unique().sorted(by: { lhs, rhs in
                if let lCat = Contact.Info.Category(rawValue: lhs.wordsToCamelCase()), let rCat = Contact.Info.Category(rawValue: rhs.wordsToCamelCase()) {
                    return lCat.intValue < rCat.intValue
                }
                return lhs.ciCompare(rhs)
            })
        case .files:
            fileCategories = files.compactMap({$0.category}).unique().sorted(by: {$0.ciCompare($1)})
        case .cases:
            break
        }

    }
}


//MARK: - Create
public extension Contact {
    func resetOtherEditingInfos() {
        for (index,element) in infos.enumerated() {
            if element.status == .editing {
                infos[index].status = .idle
            }
        }
    }
    func createInfo(category:String) async throws {
        do {
            let label = Contact.Info.Category(rawValue: category.wordsToCamelCase())?.labels.first ?? "Home"
            let newContactInfo = Contact.Info(id: UUID().uuidString, category: category, label:label, value: "Change Me!", status: .creating)
            try await create(newContactInfo)
        } catch {
            throw error
        }
    }
    func create(_ newContactInfo:Contact.Info) async throws {
        do {
            withAnimation {
                infos.append(newContactInfo)
            }
            print("Convert to Sheets")
            try await Task.sleep(for: .seconds(2))

//            _ = try await Google_Sheets.shared.append(spreadsheetID:id, sheetName:Contact.Sheet.info.rawValue, row: newContactInfo.strings)
            resetOtherEditingInfos()
            if let index = infos.firstIndex(where: {$0.id == newContactInfo.id}) {
                if infos[index].status == .creating {
                    infos[index].status = .editing
                }
            }
        } catch {
            throw error
        }
    }
    
    //Files
    func create(_ newFile:Binding<Contact.File>) async throws {
        do {
            guard !newFile.wrappedValue.category.isEmpty else { throw Contact_Error.custom("No category entered")}
            guard !newFile.wrappedValue.filename.isEmpty else { throw Contact_Error.custom("No filename entered")}
            
            guard let parentID =  self.file.parents?.first else { throw Contact_Error.custom("No contact folder found.")}
            
//            status = "Getting Folder..."
            let folder   = try await Drive.shared.get(folder: newFile.wrappedValue.category, parentID: parentID, createIfNotFound: true, caseInsensitive: true)
//            status = "Copying File..."
            let copyFile = try await Drive.shared.copy(fileID: newFile.wrappedValue.fileID, rename: newFile.wrappedValue.filename, saveTo: folder.id)
            
            //Update local Model
            newFile.wrappedValue.fileID   = copyFile.id

            //Update Google Sheet
            print("Convert to Sheets")

//            _ = try await Google_Sheets.shared.append(spreadsheetID: id, sheetName: Contact.Sheet.files.rawValue, row: newFile.wrappedValue.strings)
//            self.isLoading = false
            withAnimation {
                files.append(newFile.wrappedValue)
            }
        } catch {
            throw error
        }
    }
    func create(_ newFile:Binding<Contact.File>, upload:Contact.File.LocalURL) async throws {
        do {
            guard let parentFolderID = file.parents?.first else { throw NSError.quick("No Parent Folder")}
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
            print("Convert to Sheets")

//            _ = try await Google_Sheets.shared.append(spreadsheetID:id, sheetName:Contact.Sheet.files.rawValue, row: newFile.wrappedValue.strings)
            
            withAnimation {
                files.append(newFile.wrappedValue)
            }
        } catch {
            throw error
        }
    }
//    func fileCategorySuggestions(_ target:String) -> [String] {
//        let isEmpty = target.isEmpty
//        return fileCategories.filter { group in
//            guard group.lowercased() != target.lowercased() else { return false }
//            guard isEmpty  else { return group.ciHasPrefix(target) }
//            return true
//        }
//    }
    
    //Cases
    func add(aCase:Contact.Case) async throws {
        do {
            print("Convert to Sheets")
            try await Task.sleep(for: .seconds(2))

//            _ = try await Google_Sheets.shared.append(spreadsheetID:id, sheetName: Contact.Sheet.cases.rawValue, row: aCase.strings)
            withAnimation {
                cases.append(aCase)
            }
        } catch {
            throw error
        }
    }

}
//MARK: - Delete
public extension Contact {
    func delete(_ contactInfo:Binding<Contact.Info>) async throws {
        do {
            contactInfo.wrappedValue.status = .deleting
            try await delete(rowID: contactInfo.id, sheet: .info, isLastRow: infos.count == 1)
            withAnimation {
                _ = infos.remove(id: contactInfo.id)
            }
        } catch {
            contactInfo.wrappedValue.status = .idle
            throw error
        }
    }
    func delete(_ file:Binding<Contact.File>, deleteFile:Bool) async throws {
        do {
            file.wrappedValue.status = deleteFile ? .deleting : .removing
            if deleteFile {
                _ = try await Drive.shared.delete(ids: [file.wrappedValue.fileID])
            }
            try await delete(rowID: file.wrappedValue.id, sheet:.files, isLastRow: files.count == 1)
            withAnimation {
                _ = files.remove(id: file.wrappedValue.id)
            }
        } catch {
            file.wrappedValue.status = .idle
            throw error
        }
    }
    func delete(rowID:String, sheet:Contact.Sheet, isLastRow:Bool) async throws {
        do {
            print("Convert to Sheets")
            try await Task.sleep(for: .seconds(2))

//            if isLastRow {
//                _ = try await Google_Sheets.shared.clear(rowID:rowID, sheetName: sheet.rawValue, spreadsheetID: id)
//            } else {
//                _ = try await Google_Sheets.shared.delete(rowID:rowID, sheetName:sheet.rawValue, spreadsheetID: id)
//            }
     
        } catch {
            throw error
        }
    }
}

//MARK: - Update
public extension Contact {
    func update(_ contactInfo:Binding<Contact.Info>) async throws {
        do {
            contactInfo.wrappedValue.status = .updating
            try await update(strings: contactInfo.wrappedValue.strings, rowID: contactInfo.wrappedValue.id, sheet: .info)
            contactInfo.wrappedValue.status = .idle
          
        } catch {
            contactInfo.wrappedValue.status = .idle
           throw error
        }
    }
    func updateFileFolder(contactFile:Contact.File) async throws {
        do {
            guard let parentID = file.parents?.first else { throw Contact_Error.custom("Parent ID not found")}
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
            try await update(strings: contactFile.strings, rowID: contactFile.id, sheet: Contact.Sheet.files)
        } catch {
            throw error
        }
    }
    func update(strings:[String], rowID:String, sheet:Contact.Sheet) async throws {
        do {
            print("Convert to Sheets")
            try await Task.sleep(for: .seconds(2))

//            _ = try await Google_Sheets.shared.update(values:strings, rowID:rowID, sheetName:sheet.rawValue, spreadsheetID:id)
        } catch {
            throw error
        }
    }
}
