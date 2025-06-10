//
//  NLF_Contact_SheetRow_Value.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/4/25.
//

import SwiftUI

struct NLF_Contact_SheetRow_Value: View {
    @Binding var row : NLF_Contact.SheetRow

    var body: some View {
        TextField("Value", text: $row.value, prompt: Text("Enter text here"))
            .labelsHidden()
//            .onChange(of: row.category) { _, _ in
//                row.value = ""
//            }
//            .onChange(of: row.label) { _, _ in
//                row.value = ""
//            }
    }
}

