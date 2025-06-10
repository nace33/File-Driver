//
//  NLF_Form_CategoryField.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/28/25.
//

import SwiftUI
import BOF_SecretSauce

//MARK: - Status
struct NLF_Form_StatusPicker: View {
    @Binding var label : NLF_Form.Label
    var showStatusColor : Bool
    @Environment(NFL_FormController.self)  var controller
    
    var body: some View {
        Picker("Status", selection: $label.status) {
            ForEach(NLF_Form.DriveLabel.Status.allCases, id:\.self) { Text($0.title).tag($0)}
        }
            .foregroundStyle(showStatusColor ? label.status.color : .primary) 
//            .fixedSize()
    }
}

//MARK: - Dual Category Field
struct NLF_Form_CategoryMenu : View {
    @Binding var label : NLF_Form.Label
    @Environment(NFL_FormController.self)  var controller
    @State private var showCustom = false
    @FocusState var focusState
    @State private var proposedCategory : String = ""
    @State private var proposedSubCategory : String = ""

    
    var body: some View {
        if showCustom {
            categoryTextField
            subCategoryTextField
        } else {
            categoryMenu
        }
    }
    var menuTitle : String {
        guard !label.category.isEmpty else { return "Select a Category"}
        if label.subCategory.isEmpty {
            return label.category
        } else {
            return "\(label.category) → \(label.subCategory)"
        }
    }
    @ViewBuilder var categoryMenu : some View {
        LabeledContent("Category") {
            Menu(menuTitle) {
                let categories = controller.allCategories
                ForEach(categories, id:\.self) { cat in
                    let subCats = controller.subCategoriesOfCategory(cat)
                    if subCats.isEmpty {
                        Button(cat) { changeCategory(to: cat)  }
                    } else {
                        Menu(cat) {
                            ForEach(subCats, id:\.self) { subCat in
                                Button(subCat) { changeCategory(to: cat, subCategory: subCat)  }
                            }
                        } primaryAction: {
                            changeCategory(to: cat)
                        }
                    }
                }
                Divider()
                Button("Custom Category") {
                    showCustom.toggle()
                    changeCategory(to: "", subCategory: "")
                    focusState = true
                }
            }.fixedSize()

        }
    }
    @ViewBuilder var categoryTextField : some View {
        TextField("Category", text: $proposedCategory, prompt: Text("Custom Category"))
            .textInputSuggestions {
                ForEach(controller.categorySuggestions(withPrefix:label.category), id:\.self) { cat in
                    Text(cat)
                        .textInputCompletion(cat)
                }
            }
            .onChange(of:proposedCategory) { oldValue, newValue in
                changeCategory(to: newValue, subCategory: label.subCategory)
            }
            .focused($focusState)
    }
    @ViewBuilder var subCategoryTextField : some View {
        TextField("Sub-Category", text: $proposedSubCategory, prompt: Text("Custom Sub-Category"))
            .textInputSuggestions {
                ForEach(controller.subCategories(withPrefix: proposedSubCategory, in: label.category), id:\.self) { subCat in
                    Text(subCat)
                        .textInputCompletion(subCat)
                }
            }
            .onChange(of:proposedSubCategory) { oldValue, newValue in
                changeCategory(to: label.category, subCategory: newValue)
            }
    }
    
    func changeCategory(to string:String, subCategory:String = "") {
        if label.category != string {
            label.category = string
        }
        if label.subCategory != subCategory {
            label.subCategory = subCategory
        }
    }
}

//MARK: - Note
struct NLF_Form_NoteField: View {
    @Binding var label : NLF_Form.Label
    @Environment(NFL_FormController.self)  var controller
    
    var body: some View {
        TextField("Note", text:$label.note, prompt:Text("Must be less than 100 characters"), axis: .vertical)
    }
}
