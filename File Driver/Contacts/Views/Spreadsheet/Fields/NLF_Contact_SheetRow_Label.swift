//
//  NLF.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/4/25.
//

import SwiftUI

struct NLF_Contact_SheetRow_Label: View {
    @Binding var row : NLF_Contact.SheetRow
    let customLabels : [String]
    var didChange : ((String) -> Void)?
    init(row: Binding<NLF_Contact.SheetRow>, customLabels: [String] = [], didChange: ((String) -> Void)? = nil) {
        _row = row
        self.customLabels = customLabels
        self.didChange = didChange
    }
    @State private var createLabel : Bool = false

    var allSuggestions : [String] {
        labelSuggestions + customLabels
    }
    var hardCodedCategory : NLF_Contact.SheetRow.Category? {
        NLF_Contact.SheetRow.Category(rawValue: row.category.wordsToCamelCase())
    }
    var labelSuggestions : [String] {
        hardCodedCategory?.labels ?? []
    }
 

    
    var body: some View {
        let allSuggestions    = self.allSuggestions
        
        Group {
            if createLabel ||  allSuggestions.isEmpty {
                HStack {
                    TextField("Label", text: $row.label, prompt: Text("Enter label here"))
                        .labelsHidden()
                        .onSubmit {
                            changeLabel(to: row.label)
                        }
                    if !allSuggestions.isEmpty {
                        Button { toggleCreateLabel() } label: { Image(systemName: "xmark")}
                            .buttonStyle(.link)
                    }
                }
            } else {
                Menu(row.label.isEmpty ? "Select a Label" : row.label) {
                    ForEach(customLabels, id:\.self) { label in
                        Button(label) { changeLabel(to:label)}
                    }
                    if !customLabels.isEmpty { Divider() }
                    let suggestedLabels = allSuggestions.filter { !customLabels.contains($0)}
                    ForEach(suggestedLabels, id:\.self) { label in
                        Button(label) { changeLabel(to:label)}
                    }
                    Divider()
                    Button("Custom Label") { toggleCreateLabel()}
                }.fixedSize()
            }
        }
            .onChange(of: row.category) { _, _ in categoryChanged()  }
    }
    
 
}

extension NLF_Contact_SheetRow_Label {
    func categoryChanged() {
        guard hardCodedCategory != nil else {
            row.label = ""
            createLabel = true
            return
        }
        createLabel = false
        row.label = labelSuggestions.first ?? ""
    }

    func toggleCreateLabel() {
        createLabel.toggle()
        if createLabel {
            row.label = ""
        } else {
            row.label = labelSuggestions.first ?? ""
        }
    }
    func changeLabel(to newLabel: String) {
        row.label = newLabel
        didChange?(newLabel)
    }
}
