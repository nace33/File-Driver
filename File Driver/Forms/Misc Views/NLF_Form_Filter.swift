//
//  NLF_Form_Filter.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/28/25.
//

import SwiftUI

struct NLF_Form_Filter: View {
    var filteredCount: Int
    @Environment(NFL_FormController.self)  var controller
    @State private var isExpanded = false
    @AppStorage(BOF_Settings.Key.formsShowRetiredKey.rawValue)  var formsShowRetired  : Bool      = true
    @AppStorage(BOF_Settings.Key.formsShowDraftingKey.rawValue)  var formsShowDrafting  : Bool      = true
    @AppStorage(BOF_Settings.Key.formsShowActiveKey.rawValue)  var formsShowActive  : Bool      = true
    
    var body: some View {
        VStack(spacing:0) {
            Divider()
            if isExpanded { expandedView }
            else { compactView }
        }
    }
    @ViewBuilder var compactView : some View {
        HStack {
            let total = controller.forms.count
            if filteredCount == total {
                Text("Forms: \(filteredCount)")
            } else {
                Text("Forms: \(filteredCount), \(total - filteredCount) filtered")
            }
            Button { isExpanded.toggle()} label: {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            }
                .buttonStyle(.plain)
        }
            .padding(.top, 8)
            .padding(.bottom, 2)
            .foregroundStyle(.secondary)

    }
    @ViewBuilder var expandedView : some View {
        compactView
        Form {
            LabeledContent("Show") {
                Toggle("Drafting", isOn: $formsShowDrafting).foregroundStyle(.yellow)
                    .padding(.trailing, 8)
                Toggle("Active", isOn: $formsShowActive)
                    .padding(.trailing, 8)
                Toggle("Retired", isOn: $formsShowRetired).foregroundStyle(.red)
            }
            
            NLF_Form_Sort()
                .fixedSize()
        }
            .padding(.top, 6)
            .padding(.bottom, 8)
    }
}

#Preview {
    VStack(alignment: .leading, spacing:0) {
        List {
            Label("My Awesome Template", systemImage: "document")
            Label("Cool Template", systemImage: "folder")
            Label { Text("Cool Doc")} icon: {
                Image("Google Doc")
                    .resizable()
                    .scaledToFit()
            }
            Label { Text("Cool Sheet")} icon: {
                Image("Google Sheet")
                    .resizable()
                    .scaledToFit()
            }
                
            Text("Somethign else cool")
        }
        
        
        NLF_Form_Filter(filteredCount: 3)
            .environment(Google.shared)
            .environment(NFL_FormController())

    }
}
