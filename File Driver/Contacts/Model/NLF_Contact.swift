//
//  NLF.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//

import Foundation
import GoogleAPIClientForREST_Drive
public
struct NLF_Contact : Identifiable, Hashable {
    public var id   : String { file.id }
    let file        : GTLRDrive_File
    var name       : String { label.name }
    
    //Label
    var label : Label
    
    //Drive Label, conveinence
    private var labelFieldModifications : [GTLRDrive_LabelFieldModification] { label.labelFieldModifications }
    var         labelModification       : GTLRDrive_LabelModification        { label.labelModification       }
    

    //Spreadsheet
    public enum Sheet : String, CaseIterable { case contactInfo, files, cases }
    var info : [SheetRow] = []
    var infoCategories : [String] = []
    var files : [SheetRow] = []
    var fileCategories : [String] = []
    var cases : [SheetRow] = []
    var caseCategories : [String] = []
    

    
    static func new() -> NLF_Contact {
        let file = GTLRDrive_File()
        file.name = "New Contact"
        file.identifier = UUID().uuidString
        return NLF_Contact(file: file, label: .new())
    }
}

//MARK: Inits
///put in an extension to preserve Swift's auto inits.
public extension NLF_Contact {
    init?(file:GTLRDrive_File) {
        //required via Drive_Label - https://admin.google.com/ac/dc/labels/BaFRDNO8jAiL39Wx68qKr6PfszyBtEeIR5WRNNEbbFcb
        guard let label      = file.label(id: DriveLabel.id.rawValue) else { return nil }
        guard let statusStr  = label.value(fieldID: DriveLabel.status.rawValue) else { return nil }
        guard let status     = DriveLabel.Status(rawValue: statusStr) else { return nil }
        guard let clientStr  = label.value(fieldID: DriveLabel.client.rawValue) else { return nil }
        guard let client     = DriveLabel.ClientStatus(rawValue: clientStr) else { return nil }
        guard let firstName  = label.value(fieldID: DriveLabel.firstName.rawValue) else { return nil }
        guard let updateID   = label.value(fieldID: DriveLabel.updateID.rawValue) else { return nil }
        guard let timesStr   = label.value(fieldID: DriveLabel.timesUsed.rawValue) else { return nil }
        guard let timesUsed  = Int(timesStr) else { return nil }
        //Optionals
        let lastName   = label.value(fieldID: DriveLabel.lastName.rawValue)  ?? ""
        let groupName  = label.value(fieldID: DriveLabel.groupName.rawValue) ?? ""
        let iconID     = label.value(fieldID: DriveLabel.iconID.rawValue)  ?? ""

        
        //GTLRDrive_File
        self.file        = file
        
        //Drive_Label
        self.label = Label(status: status, client: client, firstName: firstName, lastName: lastName, updateID: updateID, groupName: groupName, iconID: iconID, timesUsed: timesUsed)
    }
}


//MARK: CRUD
///put in an extension to preserve Swift's auto inits.p
public extension NLF_Contact {
    mutating func add(_ row:NLF_Contact.SheetRow) {
        switch row.sheet {
        case .contactInfo:
            self.info.append(row)
        case .files:
            self.files.append(row)
        case .cases:
            self.cases.append(row)
        }
        sort(row.sheet)
        reloadCategories(row.sheet)
    }
    mutating func update(_ row:NLF_Contact.SheetRow) {
        switch row.sheet {
        case .contactInfo:
            print(#function)
            guard let index = self.info.firstIndex(where: { $0.id == row.id }) else { return }
            if self.info[index].category != row.category {
                self.info[index].category = row.category
            }
            if self.info[index].label != row.label {
                self.info[index].label    = row.label
            }
            if self.info[index].value != row.value {
                
                self.info[index].value   = row.value
                print("Updated: \(self.info[index].value)")
            } else {
                print("Failed: \(self.info[index].value)")
            }
        case .files:
            guard let index = self.files.firstIndex(where: { $0.id == row.id }) else { return }
            if self.files[index].category != row.category {
                self.files[index].category = row.category
            }
            if self.files[index].label != row.label {
                self.files[index].label    = row.label
            }
            if self.files[index].value != row.value {
                self.files[index].value   = row.value
            }
        case .cases:
            guard let index = self.cases.firstIndex(where: { $0.id == row.id }) else { return }
            if self.cases[index].category != row.category {
                self.cases[index].category = row.category
            }
            if self.cases[index].label != row.label {
                self.cases[index].label    = row.label
            }
            if self.cases[index].value != row.value {
                self.cases[index].value   = row.value
            }
        }
        sort(row.sheet)
        reloadCategories(row.sheet)
    }
    mutating func remove(_ row:NLF_Contact.SheetRow) {
        switch row.sheet {
        case .contactInfo:
            guard let index = self.info.firstIndex(where: { $0.id == row.id }) else { return }
            self.info.remove(at: index)
        case .files:
            guard let index = self.files.firstIndex(where: { $0.id == row.id }) else { return }
            self.files.remove(at: index)
        case .cases:
            guard let index = self.cases.firstIndex(where: { $0.id == row.id }) else { return }
            self.cases.remove(at: index)
        }
        sort(row.sheet)
        reloadCategories(row.sheet)
    }
    mutating func sort(_ sheet:NLF_Contact.Sheet) {
        switch sheet {
        case .contactInfo:
            self.info.sort(by: {$0.id < $1.id }) //ids are time intervals, earliest will be first
        case .files:
            self.files.sort(by: {$0.category.ciCompare($1.category)})
        case .cases:
            self.cases.sort(by: {$0.category.ciCompare($1.category)})
        }
    }
    mutating func reloadCategories(_ sheet:NLF_Contact.Sheet) {
        switch sheet {
        case .contactInfo:
            infoCategories = info.compactMap  { $0.category}.unique().sorted(by: {$0.ciCompare($1)})
        case .files:
            fileCategories = files.compactMap { $0.category}.unique().sorted(by: {$0.ciCompare($1)})
        case .cases:
            caseCategories = info.compactMap  { $0.category}.unique().sorted(by: {$0.ciCompare($1)})
        }
    }
}
