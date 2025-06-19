//
//  Contact_Row.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/16/25.
//

import SwiftUI

struct Case_Contact_Row: View {
    var contact : Case.Contact
    init(_ contact: Case.Contact) {
        self.contact = contact
    }
    var body: some View {
        HStack{
            Image(systemName: "person")
                .resizable()
                .frame(width:24, height:24)
           VStack(alignment:.leading, spacing: 0) {
                Text(contact.value)
                   .font(.headline)
               Text("Role")
                   .font(.caption)
            }
        }
    }
}

#Preview {
    @Previewable @State var contact1 = Case.Contact(row: ["A", "", "contact", "name", "John Doe"])!
    @Previewable @State var contact2 = Case.Contact(row: ["B", "", "contact", "name", "Frodo"])!
    @Previewable @State var contact3 = Case.Contact(row: ["C", "", "contact", "name", "Gandolf"])!
    return List {
        Case_Contact_Row(contact1)
        Case_Contact_Row(contact2)
        Case_Contact_Row(contact3)
    }.padding()
}
