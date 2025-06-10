//
//  Sidebar_Settings.swift
//  TableTest
//
//  Created by Jimmy Nasser on 4/4/25.
//

import SwiftUI
import SwiftData

struct Sidebar_Settings : View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter:#Predicate<Sidebar_Item>{ $0.isHidden }, sort:\Sidebar_Item.title) private var hiddenItems: [Sidebar_Item]

    var body: some View {
        Form {
      
            Section("Hidden Items") {
                if hiddenItems.isEmpty {
                    Text("No Hidden Items").foregroundStyle(.secondary)
                } else {
                    VStack(alignment:.leading) {
                        ForEach(hiddenItems) { hiddenItem in
                            Toggle(isOn: Bindable(hiddenItem).isHidden) {
                                Sidebar_Row(item: hiddenItem)
                            }
                        }
                    }
                }
            }
            Section("Actions") {
                LabeledContent("") {
                    VStack(alignment:.trailing) {
                        Button("Reset Sidebar") { resetSidebar() }
                        Button("Reset App To Factory Defaults") { resetApp()}
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
    }
    func resetApp() {
        try? modelContext.save()
        try? modelContext.delete(model: Sidebar_Item.self)
        try? modelContext.save()
    }
    func resetSidebar() {
        try? modelContext.save()
        try? modelContext.delete(model: Sidebar_Item.self)
        BOF_SwiftData.shared.loadDefaultSidebar()
        try? modelContext.save()
    }
}
