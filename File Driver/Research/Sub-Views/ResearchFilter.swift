//
//  ResearchFilter.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import SwiftUI

struct ResearchFilter: View {
    @AppStorage(BOF_Settings.Key.researchGroupBy.rawValue) var groupBy  : Research.Group  = .category
    @AppStorage(BOF_Settings.Key.researchShow.rawValue)   var show      : [Research.Show] = Research.Show.allCases
    
    var body: some View {
        Section("Show") {
            ForEach(Research.Show.allCases, id:\.self) { option in
                Toggle(option.title, isOn:Binding(get: {show.contains(option)}, set: { _ in toggle(option) }))
            }
        }
        Picker("Group By", selection:$groupBy) {
            ForEach(Research.Group.allCases, id:\.self) { sort in
                Text(sort.rawValue.capitalized).tag(sort)
            }
        }
            .fixedSize()
    }
    
    
    func toggle(_ showType:Research.Show) {
        if show.contains(showType) {
            show.removeAll(where: {$0 == showType})
        } else {
            show.append(showType)
        }
    }
}

#Preview {
    ResearchFilter()
}
