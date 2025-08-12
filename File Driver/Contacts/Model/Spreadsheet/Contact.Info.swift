//
//  Contact.Info.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/10/25.
//

import Foundation
import BOF_SecretSauce

public extension Contact {
    struct Info  : Identifiable, Hashable {
        public let id   : String
        var idDate      : String
        var category    : String
        var label       : String
        var value       : String


        var strings : [String] { [id, category, label, value]}
        var status  : Status
        public enum Status : String, CaseIterable, Sendable { case creating, idle, editing, updating, deleting }
        static func new(status:Status, category:String = "", label:String = "", value:String = "") -> Info {
            Info(id: UUID().uuidString, idDate: Date.idString, category: category, label:label, value: value, status: status)
        }
        var title : String { value.isEmpty ? "No Value" : value }
    
        
        enum Category : String, CaseIterable {
            //Info
            case note, date, phone, email, address,  fax, employment, website, social, relationships, number
            static var main : [Category] {[ .phone, .email, .address, .note]}
            static var misc : [Category] {[ .date, .number, .employment, .fax, .website, .social, .relationships]}
            var title    : String { rawValue.camelCaseToWords.capitalized}
            var intValue : Int {
                switch self {
                case .note:
                    0
                case .date:
                    1
                case .phone:
                    2
                case .email:
                    3
                case .address:
                    4
                case .fax:
                    5
                case .employment:
                    6
                case .website:
                    7
                case .social:
                    8
                case .relationships:
                    9
                case .number:
                    10
                }
            }
            var image : String {
                switch self {
                case .employment:
                     "hammer"
                case .phone:
                     "phone"
                case .fax:
                     "faxmachine"
                case .email:
                     "laptopcomputer.and.iphone"
                case .address:
                     "mail"
                case .website:
                     "network"
                case .relationships:
                     "person.2.crop.square.stack"
                case .note:
                    "note.text"
                case .social:
                    "person.line.dotted.person"
                case .date:
                    "calendar"
                case .number:
                    "numbers"
                }
            }
            var labels: [String] {
                switch self {
                case .phone:
                    ["Cell", "Work", "Home", "iPhone"]
                case .fax, .email, .address, .website :
                    ["Work", "Home"]
                case .employment:
                    ["Employer", "Job", "Employee"]
                case .relationships:
                    ["Spouse", "Friend", "Parent", "Mother", "Father", "Child", "Brother", "Sister", "Aunt", "Uncle", "Grandparent"]
                case .note:
                    ["Comment"]
                case .social:
                    ["twitter", "facebook", "instagram", "snapchat", "linkdIn"]
                case .date:
                    ["Birthdate", "Anniversary", "Date of Injury", "Date of Death"]
                case .number:
                    ["Social Security", "Medicare", "Claim", "Account", "Tax ID", "Lucky", "Wage"]
                }
            }
        }
        
        var suggestedLabels : [String] {
            
            if let category = Category(rawValue:self.category.wordsToCamelCase()) {
                let labels = category.labels
                return labels
//                if self.label.isEmpty || labels.firstIndex(of: self.label) != nil {
//                    return labels
//                }
//                return []
            } else {
               return [  ]
            }
        }
    }
}

import GoogleAPIClientForREST_Sheets
extension Contact.Info : GoogleSheetRow {
    var sheetID: Int { Contact.Sheet.info.intValue }
    var sheetName : String { Contact.Sheet.info.rawValue}

    init?(rowData: GTLRSheets_RowData) {
        guard let values = rowData.values else { return nil }
        guard values.count  >= 2 else { return nil }
        guard let id        = values[0].formattedValue else { return nil }
        guard let dateID    = values[1].formattedValue else { return nil }
        //Optionals
        let category        = values.count >= 3 ? values[2].formattedValue ?? "" : ""
        let label           = values.count >= 4 ? values[3].formattedValue ?? "" : ""
        let value           = values.count >= 5 ? values[4].formattedValue ?? "" : ""

        self.id         = id
        self.idDate     = dateID
        self.category   = category
        self.label      = label
        self.value      = value
        self.status     = .idle
    }

    
    var cellData: [GTLRSheets_CellData] {[
        Self.stringData(id),
        Self.stringData(idDate),
        Self.stringData(category),
        Self.stringData(label),
        Self.stringData(value)
    ]}
}
