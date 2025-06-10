//
//  Settings_Forms.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/23/25.
//

import SwiftUI

struct Settings_Forms: View {
    @AppStorage(BOF_Settings.Key.formsMasterIDKey.rawValue)  var formDriveIDKey : String = "0AGhFu4ipV3y0Uk9PVA"
    @AppStorage(BOF_Settings.Key.formsMasterIDKey.rawValue)  var formMasterID : String = "1RsIJXT9qLp73xF8xFBS9R-i1jbQnjkPe9qdbCRsfKgc"
    @AppStorage(BOF_Settings.Key.formsShowRetiredKey.rawValue)  var formsShowRetired  : Bool = true
    @AppStorage(BOF_Settings.Key.formsShowDraftingKey.rawValue) var formsShowDrafting : Bool = true
    @AppStorage(BOF_Settings.Key.formsShowActiveKey.rawValue)  var formsShowActive    : Bool = true
    @AppStorage(BOF_Settings.Key.formsShowExamplesKey.rawValue)  var showExamples  = false

    
    var body: some View {
        Form {
            NLF_Form_DriveID(alwaysShowUI: true)
            NLF_Form_Sort()
            LabeledContent("Show") {
           
                Toggle("Drafting", isOn: $formsShowDrafting).foregroundStyle(.yellow)
                    .padding(.trailing, 8)
                Toggle("Active", isOn: $formsShowActive)
                    .padding(.trailing, 8)
                Toggle("Retired", isOn: $formsShowRetired).foregroundStyle(.red)
              
            }
            Toggle("Show Examples in Preview", isOn: $showExamples)
        }.padding()
    }
}

enum Form_Sort : String, CaseIterable, Hashable, Codable {
    case alphabetically, category, subCategory
}

#Preview {
    Settings_Forms()
        .environment(Google.shared)
}
