//
//  AddToCase_Template.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import SwiftUI

struct AddToCase_Template: View {
    @Binding var template : Template
    init(_ template:Binding<Template>) {
        _template = template
    }
    @Environment(\.dismiss) var dismiss
    var body: some View {
        
        CaseSelector { aCase, destinationFolder, stack in
            Form {
                Text("Fill Out a form")
            }
        }
            .frame(minHeight:300)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") { dismiss() }
                }
            }
    }
}

