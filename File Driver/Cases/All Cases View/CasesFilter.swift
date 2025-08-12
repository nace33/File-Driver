//
//  CasesFilter.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import SwiftUI


struct CasesFilter : View {
    @AppStorage(BOF_Settings.Key.casesGroupBy.rawValue) var groupBy : Case.GroupBy = .category
    @AppStorage(BOF_Settings.Key.casesShow.rawValue)       var show : [Case.Show]  = Case.Show.allCases

    var body: some View {

        Section("Show") {
            ForEach(Case.Show.allCases, id:\.self) { option in
                Toggle(option.title, isOn:Binding(get: {show.contains(option)}, set: { _ in toggle(option) }))
            }
        }
      
        
        Picker("Group By", selection:$groupBy) {
            ForEach(Case.GroupBy.allCases, id:\.self) {sort in
                Text(sort.title)
            }
        }
            .fixedSize()
            .padding(.vertical, 8)

    }

    func toggle(_ showType:Case.Show) {
        if show.contains(showType) {
            show.removeAll(where: {$0 == showType})
        } else {
            show.append(showType)
        }
    }
}
