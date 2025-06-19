//
//  Contact.Case.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/12/25.
//

import Foundation
import GoogleAPIClientForREST_Drive


public
extension Contact {
  
    struct Case : Identifiable, Hashable {
        public let id : String //this is Date.idString type, so it is time it was created
        var caseID    : String
        var driveID   : String
        var category  : String
        var name      : String
        var strings : [String] {[id, caseID, driveID, category, name]}
        
    }
}

public extension Contact.Case {
    static func new() -> Contact.Case {
        let newRow = Contact.Case.init(id:Date.idString, caseID: "", driveID: "", category: "", name: "")
        return newRow
    }
    init?(row:[String]) {
        let count = row.count
        guard count >= 1 else { return nil }
        self.id        = row[0]
        self.caseID    = count >= 2 ? row[1] : ""
        self.driveID   = count >= 3 ? row[2] : ""
        self.category  = count >= 4 ? row[3] : ""
        self.name      = count >= 5 ? row[4] : ""
    }
    
   
}

extension Contact.Case {
    var caseCategory : Case.DriveLabel.Label.Field.Category? {
        .init(title: category)
    }
    var caseImageString : String {
        guard let caseCategory else { return "book.pages" }
        return caseCategory.icon
    }
}
