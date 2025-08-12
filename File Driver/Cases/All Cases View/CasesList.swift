//
//  CasesList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import SwiftUI
import BOF_SecretSauce

struct CasesList: View {
    @Environment(CasesDelegate.self) var delegate
    @Environment(BOF_Nav.self)       var navModel
    let showFilter : Bool
    @AppStorage(BOF_Settings.Key.casesGroupBy.rawValue) var groupBy : Case.GroupBy = .category
    @State private var scrollToCaseID : Case.ID?
    @AppStorage(BOF_Settings.Key.casesShow.rawValue)       var show : [Case.Show]  = Case.Show.allCases

    var body: some View {
        VStack(spacing:0) {
            let filteredCases = delegate.filteredCases
            ScrollViewReader { proxy in
                List(selection: Bindable(navModel).caseID) {
                    if filteredCases.isEmpty {  emptyFilteredCasesView }
                    
                    BOFBoundSections(of: filteredCases, groupedBy: groupBy.key, isAlphabetic: groupBy.isAlphabetic) { headerText in
                        Text(headerText.camelCaseToWords)
                    } row: { aCase in
                        Text(aCase.wrappedValue.title)
                    }
                        .listRowSeparator(.hidden)
                }
                    .onChange(of: scrollToCaseID) { _, newID in  proxy.scrollTo(newID)  }
                    .onChange(of: show) { oldValue, newValue in }

            }
            if showFilter {
                Filter_Footer(count: filteredCases.count, title: "Cases") {
                    CasesFilter()
                }
            }
        }
    }
    
    @ViewBuilder var emptyFilteredCasesView: some View {
        Text("No matching cases found")
            .foregroundColor(.secondary)
    }
}

