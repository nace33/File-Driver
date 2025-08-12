//
//  SelectCase.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import SwiftUI


struct SelectCase: View {
    @Environment(CasesDelegate.self) var delegate
    let selected : (Case) -> Bool

    var body: some View {
        SelectView(title: "Case", filter: Bindable(delegate).filter.string) {
            CasesList(showFilter: false)
        } menu: {
            CasesFilter()
        } selected: { caseID in
            if let aCase = delegate[caseID] {
                return selected(aCase)
            }
            return false
        }
            .task { await delegate.loadCases() }
    }
}

#Preview {
    SelectCase() { selected in
        print("Case: \(selected.title)")
        return false
    }
        .environment(CasesDelegate.shared)
        .environment(Google.shared)
}

