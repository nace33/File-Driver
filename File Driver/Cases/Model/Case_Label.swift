//
//  Case_Label.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/16/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

//this struct is intended to be nested inside the struct/class for the object the label is applied to.
extension Case {
    struct DriveLabel  {
        
        var title    : String               = ""
        var category : Label.Field.Category = .workersCompensation
        var status   : Label.Field.Status   = .consultation
        var opened   : Date                 = Date()
        var closed   : Date?                = nil
        var folderID : String               = ""
        //init
        init(title:String = "",
             category:DriveLabel.Label.Field.Category = .workersCompensation,
             status:DriveLabel.Label.Field.Status = .consultation,
             opened:Date = Date(),
             closed:Date? = nil) {
            self.title    = title
            self.category = category
            self.status   = status
            self.opened   = opened
            self.closed   = closed
        }
        
        init?(driveLabel:GTLRDrive_Label?) {
            guard let driveLabel,
                  let title  = driveLabel.value(fieldID: Label.Field.title.rawValue),
                  let cat    = Label.Field.Category(driveLabel),
                  let stat   = Label.Field.Status(driveLabel),
                  let op     = driveLabel.value(fieldID: Label.Field.opened.rawValue),
                  let opened = Date(string: op, format: .yyyymmdd),
                  let folderID = driveLabel.value(fieldID: Label.Field.folderID.rawValue)
            else { return nil }
            self.title    = title
            self.category = cat
            self.status   = stat
            self.opened   = opened
            //optionals
            self.closed   = Date(string: driveLabel.value(fieldID: Label.Field.closed.rawValue) ?? "", format: .yyyymmdd)
            self.folderID = folderID
        }
        init?(file:GTLRDrive_File) {
            guard let label =  DriveLabel(driveLabel: file.label(id: Case.DriveLabel.Label.id.rawValue)) else {
                return nil
            }
            self = label
        }
    }
}


//MARK: Label Modifications
extension Case.DriveLabel {
    //Objects that can be uploaded to Google to modify labels on a Drive File
    //Ex: _ = try await Google_Drive.shared.labelModify(labelID: DriveLabel.Label.id.rawValue, modifications:[label.labelModification], on:fileToModify.id)
    fileprivate var labelFieldModifications : [GTLRDrive_LabelFieldModification] {
        var mods = [GTLRDrive_LabelFieldModification]()
        if let mod =  Google_Drive.shared.label(modify: Label.Field.title.rawValue, value: title, valueType: .text) {
            mods.append(mod)
        }
        if let mod =  Google_Drive.shared.label(modify: Label.Field.category.rawValue, value:category.rawValue, valueType: .selection) {
            mods.append(mod)
        }
        if let mod =  Google_Drive.shared.label(modify: Label.Field.status.rawValue, value:status.rawValue, valueType: .selection) {
            mods.append(mod)
        }
        if let mod =  Google_Drive.shared.label(modify: Label.Field.opened.rawValue, value: opened, valueType: .date) {
            mods.append(mod)
        }
        if let mod =  Google_Drive.shared.label(modify: Label.Field.closed.rawValue, value: closed, valueType: .date) {
            mods.append(mod)
        }
        return mods
    }
    var labelModification       : GTLRDrive_LabelModification {
        Google_Drive.shared.label(modify: Label.id.rawValue, fieldModifications: labelFieldModifications)
    }
}

//MARK: Label Modifications
extension Case.DriveLabel : CustomStringConvertible{
    var description : String {
        var str = "\n"
        str    += "Title:\t\t\(title)\n"
        str    += "Category:\t\(category)\n"
        str    += "Status:\t\t\(status)\n"
        str    += "Opened:\t\t\(opened)\n"
        str    += "Closed:\t\t\(closed ?? Date())\n"
        return str
    }
    
    var consultationHeader : String {
        "\(opened.year % 100)_\(category.abbreviation)"
    }
    var consultationFolder : String {
        "\(opened.yyyymmdd) \(title)"
    }
    var driveName : String {
        "[\(consultationHeader)] \(title)"
    }
    var caseSheetName : String {
        "-Case (\(title))"
    }
   
}


//MARK: Hard Coded From Google Drive Labels
///https://admin.google.com/ac/dc/labels/7vPlRGn3rEJZB7TNkyHOt8Mv1DrfecyXgjmSNNEbbFcb
extension Case.DriveLabel {
    enum Label : String, CaseIterable {
        case id = "7vPlRGn3rEJZB7TNkyHOt8Mv1DrfecyXgjmSNNEbbFcb" //Hard Coded
        
        enum Field : String, CaseIterable {
            case title    = "A04C6E1BFF" //text
            case category = "708231DBFF" //options
            case status   = "E553BB1D5D" //options
            case opened   = "682D39D8FE" //date
            case docket   = "845D19B07C" //text
            case closed   = "F155852F24" //date
            case folderID = "8752BE43E1" //text
            //Utility
            var title : String {
                switch self {
                case .title:
                    "Title"
                case .category:
                    "Type"
                case .status:
                    "Status"
                case .opened:
                    "Opened"
                case .docket:
                    "Docket"
                case .closed:
                    "Closed"
                case .folderID:
                    "Folder"
                }
            }
            
            enum Category : String, CaseIterable, Comparable {
                static func < (lhs: Label.Field.Category, rhs: Label.Field.Category) -> Bool {
                    lhs.rawValue == rhs.rawValue
                }
                
                case personalInjury         = "251C51F5E5"
                case workersCompensation    = "F2EB8F42BF"
                case wrongfulDeath          = "E074427AA7"
                case insuranceDispute       = "E80525A0F6"
                case badFaith               = "AAD3187053"
                case estate                 = "A5F13FDDFD"
                case ssdi                   = "E876386174"
                case subrogation            = "5C55C3DBA1"
                case miscellaneous          = "D0CB025229"
                //init
                init?(_ driveLabel:GTLRDrive_Label) {
                    guard let val = driveLabel.field(id:Label.Field.category.rawValue)?.selection?.first,
                          let a  = Category.allCases.first(where: {$0.rawValue == val}) else { return  nil }
                    self = a
                }
                init?(title:String) {
                    guard let cat = Category.allCases.first(where: {$0.title == title}) else {
                        return nil
                    }
                    self = cat
                }
                //Utility
                var intValue : Int {
                    Category.allCases.firstIndex(of: self) ?? -1
                }
                var title : String {
                    switch self {
                    case .personalInjury:
                        "Personal Injury"
                    case .workersCompensation:
                        "Workers Compensation"
                    case .wrongfulDeath:
                        "Wrongful Death"
                    case .insuranceDispute:
                        "Insurance"
                    case .badFaith:
                        "Bad Faith"
                    case .estate:
                        "Estate"
                    case .ssdi:
                        "Disability"
                    case .subrogation:
                        "Subrogation"
                    case .miscellaneous:
                        "Miscellaneous"
                    }
                }
                var abbreviation : String {
                    switch self {
                    case .personalInjury:
                        "PI"
                    case .workersCompensation:
                        "WC"
                    case .wrongfulDeath:
                        "WD"
                    case .insuranceDispute:
                        "INS"
                    case .badFaith:
                        "BAD"
                    case .estate:
                        "EST"
                    case .ssdi:
                        "DIS"
                    case .subrogation:
                        "SUB"
                    case .miscellaneous:
                        "MIS"
                    }
                }
                var icon  : String {
                    switch self {
                    case .personalInjury:
                        "car.side.rear.and.collision.and.car.side.front"
                    case .workersCompensation:
                        "hammer"
                    case .wrongfulDeath:
                        "wrongwaysign"
                    case .insuranceDispute:
                        "book.pages"
                    case .badFaith:
                        "bolt.trianglebadge.exclamationmark"
                    case .estate:
                        "hands.sparkles.fill"
                    case .ssdi:
                        "figure.roll"
                    case .subrogation:
                        "figure.stand.line.dotted.figure.stand"
                    case .miscellaneous:
                        "questionmark.circle.dashed"
                    }
                }
            }
            
            enum Status : String, CaseIterable, Comparable {
                case consultation           = "5A3A782EBC"
                case investigation          = "EC33FC2C43"
                case active                 = "74E8107878"
                case stayed                 = "8DFEDAA9BE"
                case closed                 = "8435058392"
                //init
                init?(_ driveLabel:GTLRDrive_Label) {
                    guard let val = driveLabel.field(id:Label.Field.status.rawValue)?.selection?.first,
                          let a  = Status.allCases.first(where: {$0.rawValue == val}) else { return  nil }
                    self = a
                }
                static func < (lhs: Label.Field.Status, rhs: Label.Field.Status) -> Bool {
                    lhs.rawValue == rhs.rawValue
                }
                //Utility
                var title : String {
                    switch self {
                    case .consultation:
                        "Consultation"
                    case .investigation:
                        "Investigation"
                    case .active:
                        "Active"
                    case .stayed:
                        "Stayed"
                    case .closed:
                        "Closed"
                    }
                }
                var intValue : Int {
                    Status.allCases.firstIndex(of: self) ?? -1
                }
                var color : Color {
                    switch self {
                    case .consultation:
                       .yellow
                    case .investigation:
                        .orange
                    case .active:
                        .primary
                    case .stayed:
                        .gray
                    case .closed:
                        .red
                    }
                }
            }
        }
    }
    
    //MARK: Drive Queries
    static func query(status:Label.Field.Status, includeTrashed:Bool? = nil) -> String {
        return if let includeTrashed {
            "labels/\(Label.id.rawValue).\(Label.Field.status.rawValue) = '\(status.rawValue)' and trashed=\(includeTrashed)"
        } else {
            "labels/\(Label.id.rawValue).\(Label.Field.status.rawValue) = '\(status.rawValue)'"
        }
    }
    static func query(statuses:[Label.Field.Status], includeTrashed:Bool = false) -> String {
        let str = statuses.compactMap {query(status:$0) }.joined(separator: " OR ")
        return "(" + str + ") and trashed=\(includeTrashed)"
    }
    static func query(notStatus:Label.Field.Status) -> String {
        query(statuses:Label.Field.Status.allCases.filter { $0 != notStatus})
    }
}

/*
Printed: 3/23/2025
 
Field:    Title    ID: A04C6E1BFF    Type: text
Field:    Type    ID: 708231DBFF    Type: list
        Personal Injury ID: 251C51F5E5
        Workers Compensation ID: F2EB8F42BF
        Wrongful Death ID: E074427AA7
        Insurance Dispute ID: E80525A0F6
        Bad Faith ID: AAD3187053
        Estate ID: A5F13FDDFD
        SSDI ID: E876386174
        Subrogation ID: 5C55C3DBA1
        Miscellaneous ID: D0CB025229
Field:    Opened    ID: 682D39D8FE    Type: date
Field:    Closed    ID: F155852F24    Type: date
Field:    Status    ID: E553BB1D5D    Type: list
        Consultation ID: 5A3A782EBC
        Investigation ID: EC33FC2C43
        Active ID: 74E8107878
        Stayed ID: 8DFEDAA9BE
        Closed ID: 8435058392
Field:    Docket    ID: 845D19B07C    Type: text
*/
