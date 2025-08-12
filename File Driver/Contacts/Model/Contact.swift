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
    
//    var isLoading = false
//    var error  : Error?
    
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




//MARK: - Load
public extension Contact {
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
        
        }
    }
}


