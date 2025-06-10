//
//  NLF_Contact_View_Info.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/4/25.
//

import SwiftUI

struct NLF_Contact_Info_View: View {
    @Binding var contact : NLF_Contact
    @Binding var isEditing : Bool
    @Binding var isLoading : Bool

    @AppStorage(BOF_Settings.Key.contactSheetKey.rawValue)   var sheet : NLF_Contact.Sheet = .contactInfo

    @Environment(NLF_ContactsController.self) var controller


    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                let categories = contact.infoCategories
                noCategoriesView(count: categories.count)
                
                ForEach(categories, id:\.self) { category in
                    NLF_Contact_Info_Category(contact: $contact, isEditing: $isEditing, category: category)
                        
                    ForEach(contact.info.filter({$0.category == category})) { info in
                        NLF_Contact_Info_SheetRow(contact: $contact, isEditing: $isEditing, info:info)
                    }
//                    ForEach($contact.info ) { info in
//                        if info.wrappedValue.category == category {
//                            NLF_Contact_Info_SheetRow(contact: $contact, isEditing: $isEditing, info:info)
//                        }
//                    }
                    
//                    if category != categories.last {
//                        Divider().padding(.vertical, 10)
//                    }
                }
            }
        }
    }
}



//MARK: - View Builders
extension NLF_Contact_Info_View {
    @ViewBuilder func noCategoriesView(count:Int) -> some View {
        if count == 0 {
            Text("No \(sheet.rawValue.camelCaseToWords())")
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(.secondary)
        }
    }
}
