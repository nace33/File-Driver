//
//  Contact.Info.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/10/25.
//

import Foundation
import BOF_SecretSauce
extension Contact.Info {
    
    init?(row:[String]) {
        let count = row.count
        guard count >= 1 else { return nil }
        self.id         = row[0]
        self.category   = count >= 2 ? row[1] : ""
        self.label      = count >= 3 ? row[2] : ""
        self.value      = count >= 4 ? row[3] : ""
        self.status = .idle
    }
}
public
extension Contact {
    struct Info  : Identifiable, Hashable {
        public let id       : String
        var category : String
        var label    : String
        var value    : String


        var strings : [String] { [id, category, label, value]}
        var status  : Status
        public enum Status : String, CaseIterable { case creating, idle, editing, updating, deleting }
        static func new(status:Status, category:String = "", label:String = "", value:String = "") -> Info {
           Info(id: UUID().uuidString, category: category, label:label, value: value, status: status)
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
