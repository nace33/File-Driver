//
//  Contacts_List.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/16/25.
//

import SwiftUI

struct Case_Contacts_List: View {
    let aCase : Case_OLD
    @State private var selected : Case_OLD.Contact?
    
    var body: some View {
        List(selection: $selected) {
            if aCase.rootContacts.isEmpty { Text("No contacts").foregroundStyle(.secondary) }
            ForEach(aCase.rootContacts, id:\.self) { contact in
                Case_Contact_Row(contact)
            }
        }
            .inspector(isPresented: Binding(get: {selected != nil}, set: {_ in })) {
                if let selected {
                    Case_Contact_Details(aCase: aCase, contact: selected)
                } else { Text("No Selection").foregroundStyle(.secondary)}
            }
    }
}

//#Preview {
//    Contacts_List()
//}
