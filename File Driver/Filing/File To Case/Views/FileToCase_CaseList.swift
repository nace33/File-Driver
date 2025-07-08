//
//  Filer_CaseList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/2/25.
//

import SwiftUI

struct Filer_CaseList: View {
    @Environment(FileToCase_Delegate.self) var delegate

    var body: some View {
        ScrollViewReader { proxy in
            List(selection:Bindable(delegate).selectedCase) {
                if delegate.categories.isEmpty {
                    Text("Filing is only used after cases have been created.").foregroundStyle(.secondary)
                }
                else {
                    if delegate.suggestions.count > 0 {
                        FileToCase_Suggestions()
                    }
                    //suggestions are already filted out in delegate.filteredCases
                    ForEach(delegate.categories, id:\.self) { category in
                        let casesInCategory = delegate.filteredCases.filter { $0.category == category }
                        if casesInCategory.count > 0 {
                            Section(category.title) {
                                ForEach(casesInCategory, id:\.self) { aCase in
                                    Label {
                                        Text(aCase.title)
                                    } icon: {
                                        Image(aCase.file.mime.title)
                                            .resizable()
                                            .scaledToFit()
                                    }
                                        .tag(aCase.id)
                                }
                            }
                        }
                    }
                        .listRowSeparator(.hidden)
                        .onChange(of: delegate.scrollToCaseID) { _, newID in  proxy.scrollTo(newID)  }
                        .alternatingRowBackgrounds()

                }
            }
            .contextMenu(forSelectionType: Case.self, menu: {_ in}, primaryAction: { items in
                print("Items: \(items)")
                if let item = items.first {
                    delegate.doubleClicked(item)
                }
            })
        }
    }

}

