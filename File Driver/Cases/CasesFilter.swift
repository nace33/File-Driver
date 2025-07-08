//
//  CasesFilter.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import SwiftUI


struct CasesFilter : View {
    let count : Int
    @State private var isExpanded = false
    @State private var isInside = false
    @AppStorage(BOF_Settings.Key.casesSort.rawValue) var sortBy : Case.SortBy = .category

    var body: some View {
        Filter_Footer(count: count, title: "Cases") {
            
//            LabeledContent("Show") {
//                Toggle(isOn: $showVisible) { Text("Active").foregroundStyle(.green)}.padding(.trailing, 8)
//                Toggle(isOn: $showHidden)  { Text("Hidden").foregroundStyle(.orange)}.padding(.trailing, 8)
//                Toggle(isOn: $showPurge)   { Text("Deleted").foregroundStyle(.red)}
//            }
//            Toggle(isOn: $showColors)  { Text("Colors In Name")}
//            Toggle(isOn: $showImage)  { Text("Profile Image")}
//            
            Picker("Sort By", selection:$sortBy) {
                ForEach(Case.SortBy.allCases, id:\.self) {sort in
                    Text(sort.title)
                }
            }
                .fixedSize()
                .padding(.vertical, 8)
//
//            Picker("Display", selection:$lastNameIsFirst) {
//                Text("First Name First").tag(false)
//                Text("Last Name First").tag(true)
//            }
//                .fixedSize()
        }
    }
}
