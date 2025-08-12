//
//  Cases_Detail.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import SwiftUI

struct Cases_Detail: View {
    @Environment(CasesDelegate.self) var delegate
    @Environment(BOF_Nav.self)       var navModel
    var body: some View {
        Group {
            if let aCaseID = navModel.caseID, let aCase = Bindable(delegate).cases.first(where: {$0.id == aCaseID}) {
                Text("Show a case summary type of view\n\n\(aCase.wrappedValue.title)")
            } else {
                ContentUnavailableView("No Case Selected", systemImage: Sidebar_Item.Category.cases.iconString)
            }
        }
    }
}

#Preview {
    Cases_Detail()
}
