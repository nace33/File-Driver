//
//  NLF.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//

import SwiftUI

struct NLF_Contact_NameField : View {
    @Binding var label : NLF_Contact.Label
    init(_ label: Binding<NLF_Contact.Label>) {
       _label = label
    }
    @State private var isCompany = false
    var body: some View {
        LabeledContent {
            HStack {
                TextField(isCompany ? "Name" : "First Name", text: $label.firstName, prompt: Text(isCompany ? "Name" : "First Name"))
                    .labelsHidden()
                    .fixedSize()
                
                if !isCompany {
                    TextField("Last Name", text: $label.lastName, prompt: Text("Last Name"))
                        .labelsHidden()
                        .fixedSize()
                }
            }
        } label: {
            Picker("Type", selection:$isCompany) {
                Text("Person").tag(false)
                Text("Company").tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .onChange(of: isCompany) { oldValue, newValue in
                label.lastName = ""
            }
        }
    }
}

