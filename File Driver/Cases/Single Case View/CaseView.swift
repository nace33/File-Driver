//
//  CaseView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/2/25.
//

import SwiftUI

struct CaseView: View {
    @Environment(BOF_Nav.self) var navModel
    @Binding var aCase : Case
    @State private var loader = VLoader_Item()
    
    var body: some View {
        VStackLoacker(loader: $loader) {
            loader.clearError()
        } content: {
            TabView {
                ForEach(Case.ViewIndex.allCases, id:\.self) { viewIndex in
                    switch viewIndex {
                    case .trackers:
                        Case_TrackersView($aCase)
                            .tabItem {
                                Label("Trackers", systemImage: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
                            }
                    }
                }
            }
            .tabViewStyle(.sidebarAdaptable)
//            HSplitView {
//                List(selection: Bindable(navModel).caseView) {
//                    ForEach(Case.ViewIndex.allCases, id:\.self) { viewIndex in
//                        switch viewIndex {
//                        case .trackers:
//                            trackerRow
//                        }
//                        
//                    }
//                }
//                .listStyle(.sidebar)
////                    .frame(width:100)
//                .frame(minWidth:120)
//
//                Group {
//                    switch navModel.caseView {
//                    case .trackers:
//                        Case_TrackersView($aCase)
//                    }
//                }
//                    .layoutPriority(1)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            }
        }
            .task(id:aCase.id) { await loadCaseSpreadsheet() }
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button("", systemImage: "arrow.clockwise") {  Task { await loadCaseSpreadsheet() } } .disabled(loader.isLoading)
                }
            }
    }
    

    func loadCaseSpreadsheet() async {
        do {
            loader.status = "Loading \(aCase.title)"
            loader.start()
            try await aCase.load(sheets:Case.Sheet.allCases)
            
            loader.stop()
        } catch {
            loader.stop(error)
        }
    }
}

extension CaseView {
    @ViewBuilder var trackerRow : some View {
//        let categories = aCase.trackers.map(\.category).unique().sorted(by: {$0.intValue < $1.intValue})
//        if categories.count > 0 {
//            DisclosureGroup(Case.ViewIndex.trackers.title) {
//                ForEach(categories, id:\.self) { Text($0.title)}
//            }
//        } else {
            Text(Case.ViewIndex.trackers.title)
//        }
    }
}
