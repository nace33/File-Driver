//
//  Contact_Details.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/16/25.
//

import SwiftUI

struct Case_Contact_Details: View {
    var aCase : Case_OLD
    var contact : Case_OLD.Contact
    init(aCase: Case_OLD, contact: Case_OLD.Contact) {
        self.aCase = aCase
        self.contact = contact
    }
    @State private var details : [Case_OLD.Contact] = []
    
    var body: some View {
        Form {
            if details.isEmpty { Text("No Details").foregroundStyle(.secondary) }
            
            ForEach(categorySections, id:\.self) { info in
                let detailedInfo = details(category: info)
                if detailedInfo.isNotEmpty {
                    Section(info.title) {
                        ForEach(detailedInfo, id:\.self) { detail in
                            LabeledContent(detail.label, value: detail.value)
                        }
                    }
                }
            }
        }
            .formStyle(.grouped)
            .task(id:contact.id) { loadDetails()  }
    }
    func loadDetails() {
        self.details = aCase.details(of: contact)
    }
    var categorySections : [Case_OLD.Contact.Category] { [
        .role, .credential, .email, .phone, .address, .fax, .social, .website, .date, .number, .other, .note
    ]}

    func details(category:Case_OLD.Contact.Category) -> [Case_OLD.Contact] {
        details.filter { $0.category == category}
    }
    /*
case contact
case centralID //for linking to a central database
case folder, photo    //where to save documents in this case (multiple contacts can save to same place)
case note
case role
case email, phone, address, fax, social, website
case date
case number
case credential
case other
var info : [Category] {[.email, .phone, .address, .fax, .social, .website ]}
    */
}

//#Preview {
//    Contact_Details()
//}
