//
//  CaseSpreadsheet.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import Foundation
import GoogleAPIClientForREST_Drive

@Observable
final class Case  {
    var file  : GTLRDrive_File
    var label : DriveLabel
    
    init(file: GTLRDrive_File, label: DriveLabel) {
        self.file = file
        self.label = label
    }
    convenience init?(_ file: GTLRDrive_File) {
        guard let label = DriveLabel(file: file) else { return nil }
        self.init(file: file, label: label)
    }

    
    //variables that get loaded from the spreadsheet
    var isLoading                        = false
    var folders     : [Case.Folder]      = []
    var tags        : [Case.Tag]         = []
    var contacts    : [Case.Contact]     = []
    var contactData : [Case.ContactData] = []
    var files       : [Case.File]        = []
    var tasks       : [Case.Task]        = []
    var trackers    : [Case.Tracker]     = []

    //Permissions
    var permissions : [GTLRDrive_Permission] = []

    //Used for suggestions
    var filingSheetRows : [any SheetRow] {
       folders +
       contacts +
       contactData.filter ({ $0.category == "email"}) +
       tags +
       files
    }
}

//MARK: Computed Properties {
extension Case {
    ///From File
    var parentID : String                          { file.parents?.first ?? "" }
    var driveID  : String                          { file.driveId        ?? "" }
    
    ///From Label
    var title    : String                          { label.title   }
    var folderID : String                          { label.folderID}
    var category : DriveLabel.Label.Field.Category { label.category }
    var status   : DriveLabel.Label.Field.Status   { label.status   }
    var opened   : Date                            { label.opened   }
    var closed   : Date?                           { label.closed   }
    
    var parentFolder : GTLRDrive_File {
        let folder = GTLRDrive_File()
        folder.identifier = folderID
        folder.name = title
        folder.mimeType = GTLRDrive_File.MimeType.sheet.rawValue
        return folder
    }
    
    static func allCases() async throws -> [Case] {
        do {
            return try await Drive.shared.get(filesWithLabelID:Case.DriveLabel.Label.id.rawValue)
                                         .sorted(by: {$0.title.lowercased() < $1.title.lowercased()})
                                         .compactMap { Case($0)}
        } catch {
            throw error
        }
    }
    static func getCase(id:String) async throws -> Case {
        do {
            let file = try await Drive.shared.get(fileID: id, labelIDs: [Case.DriveLabel.Label.id.rawValue])
            guard let foundCase = Case(file) else { throw NSError.quick("Case not found for \(id)")}
            return foundCase
        } catch {
            throw error
        }
    }
}


//MARK: Protocols {
extension Case : Hashable, Identifiable {
    var id : String { file.id }
    static func == (lhs: Case, rhs: Case) -> Bool { lhs.id == rhs.id  }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}


//MARK: - LoadSheets
extension Case {
    func load(sheets:[Sheet]) async throws {
        do {
            isLoading = true
            let start = CFAbsoluteTimeGetCurrent()

            let spreadsheet = try await Sheets.shared.getSpreadsheet(id, ranges: sheets.compactMap(\.rawValue))
            for range in sheets {
                guard let rowData = spreadsheet.rowData(range: range.rawValue, dropHeader: true) else { continue }
                switch range {
                case .contacts:
                    contacts    = rowData.compactMap { Case.Contact(rowData: $0)}
                case .tags:
                    tags        = rowData.compactMap { Case.Tag(rowData: $0)}
                case .folders:
                    folders     = rowData.compactMap { Case.Folder(rowData: $0)}
                case .contactData:
                    contactData = rowData.compactMap { Case.ContactData(rowData: $0)}
                case .files:
                    files       = rowData.compactMap { Case.File(rowData: $0)}
                case .tasks:
                    tasks       = rowData.compactMap { Case.Task(rowData: $0)}
                case .trackers:
                    trackers    = rowData.compactMap { Case.Tracker(rowData:$0)}
                }
            }
            isLoading = false
            let diff = CFAbsoluteTimeGetCurrent() - start
            print("Loading \(title) Data Took: \(diff) seconds")
        } catch {
            print("Error \(#function)")
            isLoading = false
            throw error
        }
    }

    func loadPermissions() async throws {
        do {
            isLoading = true
            permissions = try await Drive.shared.permissions(fileID:id)
            isLoading = false
        } catch {
            print("Error \(#function)")
            isLoading = false
            throw error
        }
    }
}



//MARK: - Get
extension Case {
    func tags(with ids:[String]) -> [Case.Tag] {
        guard ids.count > 0 else { return [] }
        return tags.filter { ids.contains($0.id)}
    }
    func contacts(with ids:[String]) -> [Case.Contact] {
        guard ids.count > 0 else { return [] }
        return contacts.filter { ids.contains($0.id)}
    }
    func contactData(with contactIDs:[String], category:String? = nil) -> [Case.ContactData] {
        if let category = category?.lowercased() {
            guard contactIDs.count > 0 else { return contactData.filter { $0.category.lowercased() == category } }
            return contactData.filter {
                contactIDs.contains($0.contactID) && $0.category.lowercased() == category
            }
        } else {
            guard contactIDs.count > 0 else { return contactData }
            return contactData.filter {
                contactIDs.contains($0.contactID)
            }
        }
    }
}


//MARK: - Properties
extension Case {
    var driveFolders : [GTLRDrive_File] {
        let mimeType = GTLRDrive_File.MimeType.folder.rawValue
        return folders.compactMap { folder in
            let driveFolder = GTLRDrive_File()
            driveFolder.name = folder.name
            driveFolder.identifier = folder.folderID
            driveFolder.mimeType = mimeType
            return driveFolder
        }
    }
 }

//MARK: - Sheet Rows
extension Case {
    func isInSpreadsheet(_ id:String, sheet:Case.Sheet) -> Bool {
        switch sheet {
        case .contacts:
            contacts.first(where: {$0.id == id }) != nil
        case .contactData:
            contactData.first(where: {$0.id == id }) != nil
        case .tags:
            tags.first(where: {$0.id == id }) != nil
        case .folders:
            folders.first(where: {$0.id == id }) != nil
        case .files:
            files.first(where: {$0.id == id }) != nil
        case .tasks:
            tasks.first(where: {$0.id == id }) != nil
        case .trackers:
            trackers.first(where: {$0.id == id }) != nil
        }
    }
}

//MARK: - UI Enums
extension Case {
    enum ViewIndex : String, CaseIterable, Codable {
        case trackers
        var title : String { rawValue.capitalized}
    }
}
