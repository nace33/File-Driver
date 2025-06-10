//
//  NLF.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/4/25.
//

import SwiftUI

struct NLF_Contact_SheetRow_Category: View {
    @Binding var row : NLF_Contact.SheetRow
    let customCategories : [String]
    init(row: Binding<NLF_Contact.SheetRow>, customCategories: [String] = []) {
        _row = row
        self.customCategories = customCategories
    }
    @State private var customCategory : Bool = false
    
    
    
    var body: some View {
        if customCategory {
            HStack {
                TextField("Category", text: $row.category, prompt: Text("Enter category here"))
                    .labelsHidden()
                Button { customCategory.toggle() } label: { Image(systemName: "xmark")}
                    .buttonStyle(.link)
            }
        } else {
            Menu(row.category.isEmpty ? "Select a Category" : row.category) {
                ForEach(customCategories, id:\.self) { category in
                    Button(category) { row.category = category}
                }
                if !customCategories.isEmpty { Divider() }
                ForEach(NLF_Contact.SheetRow.Category.allCases.map(\.title), id:\.self) { category in
                    Button(category) { row.category = category}
                }
                Divider()
                Button("Custom") { row.category = ""; customCategory.toggle()}
            }.fixedSize()
        }
    }
}
