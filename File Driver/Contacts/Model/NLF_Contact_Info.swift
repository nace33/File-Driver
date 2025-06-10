//
//  NLF_Contact_Info.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/4/25.
//

import Foundation

public extension NLF_Contact {
    struct SheetRow  : Identifiable, Hashable {
        let sheet    : NLF_Contact.Sheet
        public let id       : String
        var category : String
        var label    : String
        var value    : String
        
        init?(sheet:NLF_Contact.Sheet, row:[String]) {
            let count = row.count
            guard count >= 1 else { return nil }
            self.sheet      = sheet
            self.id         = row[0]
            self.category   = count >= 2 ? row[1] : ""
            
            self.label      = count >= 3 ? row[2] : ""
            self.value      = count >= 4 ? row[3] : ""
            self.status = .idle
        }

        var strings : [String] { [id, category, label, value]}
        var status  : Status
        public enum Status : String, CaseIterable { case idle, editing, updating, deleting }
        static func new(sheet:NLF_Contact.Sheet, status:Status, category:String = "", label:String = "", value:String = "") -> SheetRow {
           var sheet = SheetRow(sheet: sheet, row: [Date.idString,category,label,value])!
            sheet.status = status
            return sheet
        }
        
        enum Category : String, CaseIterable {
            //Info
            case employment, phone, fax, email, address, website, social, relationships, note, date, number
            var title    : String { rawValue.camelCaseToWords().capitalized}
            var intValue : Int { Category.allCases.firstIndex(of: self) ?? -1 }
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
                    ["twitter", "facebook", "instagram", "snapchat"]
                case .date:
                    ["Birthdate", "Anniversary", "Date of Injury", "Date of Death"]
                case .number:
                    ["Social Security", "Medicare", "Claim", "Account", "Tax ID", "Lucky", "Wage"]
                }
            }
        }
    }
    

}


////MARK: - Created
/////The id is actually just the timeIntervalSinceReferenceDate
/////Whiich is the interval between the date object and 00:00:00 UTC on 1 January 2001.
//public extension NLF_Contact.SheetRow {
//    //this should only be used in the original .init
//    static var timeIntervalSinceReferenceDate : String {
//        Date().timeIntervalSinceReferenceDate.string()
//    }
//    var created : Date? {
//        guard let timeIntervalSinceReferenceDate = Double(id) else { return nil }
//        return Date(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate)
//            .convertToTimeZone(initTimeZone: .gmt, timeZone: .current)
//    }
//    func created(timeZone:TimeZone) -> Date? {
//        guard let created else { return nil }
//        return created.convertToTimeZone(initTimeZone: .gmt, timeZone: timeZone)
//    }
//}
//
