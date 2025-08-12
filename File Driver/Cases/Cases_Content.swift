//
//  CasesView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import SwiftUI

struct Cases_Content: View {
    @Environment(CasesDelegate.self) var delegate
    @Environment(BOF_Nav.self)       var navModel

    @State private var showNewCaseSheet = false
    @State private var editCase : Case?
    @State private var scrollToCaseID : Case.ID?
    
    var body: some View {
        VStackLoacker(loader: Bindable(delegate).loader) {
            NavigationStack(path: Bindable(navModel).casePath) {
                VStack(spacing:0) {
                    CasesList(showFilter: true)
                        .contextMenu(forSelectionType: Case.ID.self,
                                     menu:          { listMenu($0 )      },
                                     primaryAction: { listDoubleClick($0)})
                        .searchable(text:   Bindable(delegate).filter.string,
                                    tokens: Bindable(delegate).filter.tokens,
                                    placement:.automatic,
                                    prompt: Text("Type to filter, or use #, $ for tags")) { token in
                            Text(token.title)
                        }
                        .searchSuggestions { delegate.filter.searchSuggestions }
                }
                    .frame(minWidth:300, idealWidth: 400)
                    .inspector(isPresented: .constant(true)) {
                        Cases_Detail()
                            .inspectorColumnWidth(min: 500, ideal: 500)
                    }
                    .navigationDestination(for: Case.ID.self) { aCaseID in
                        caseView(aCaseID)
                    }
            }
        }
            .disabled(delegate.loader.isLoading)
            .sheet(isPresented: $showNewCaseSheet) {
                NewCase { newCase in
                    delegate.cases.append(newCase)
                    navModel.caseID  = newCase.id
                    scrollToCaseID   = newCase.id
                }
            }
            .sheet(item: $editCase) { aCase in
                if let aCase = Bindable(delegate).cases.first(where: {$0.id == aCase.id}) {
                    EditCase(aCase)
                } else {
                    Form {
                        Text("Could not find case to edit")
                        Button("Close") { editCase = nil}
                    }.padding()
                }
            }
            .task { await delegate.loadCases() }
            .environment(delegate)
            .toolbar { toolbarContent  }
    }
}



//MARK: Action
extension Cases_Content {
    func listDoubleClick(_ caseIDs:Set<Case.ID>) {
        if let id = caseIDs.first {
            navModel.casePath.append(id)
        }
    }
}


//MARK: View Builders
extension Cases_Content {
    @ToolbarContentBuilder var toolbarContent : some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button { Task { await delegate.loadCases() }} label: {Image(systemName: "arrow.clockwise")}
            Button("New") {  showNewCaseSheet = true }
            Button("Edit") {
                if let selectedCaseID = navModel.caseID, let aCase = delegate[selectedCaseID] {
                    editCase = aCase
                }
            }
                .disabled(navModel.caseID == nil)
        }
    }
    @ViewBuilder func listMenu(_ caseIDs:Set<Case.ID>) -> some View {
        if let aCaseID = caseIDs.first, let aCase = delegate[aCaseID] {
            Button("Edit") { editCase = aCase}
            Menu("Info") {
                Text("Type\t"   + aCase.category.title)
                Text("Status\t" + aCase.status.title)
                Text("Opened\t" + aCase.opened.mmddyyyy)
                if aCase.status == .closed, let closed = aCase.closed {
                    Text("Closed\t\(closed.mmddyyyy)")
                }
                Divider()
                alignmentMenu(aCaseID)
            }
            SidebarItemToggleButton(url:aCase.file.url, category: .aCase, title: aCase.title)
        }
    }
    @ViewBuilder func alignmentMenu(_ aCaseID:String) -> some View {
        Menu("Alignment") {
            Menu("Wrap") {
                ForEach(Sheets.WrapStrategy.allCases, id:\.self) { wrap in
                    Button(wrap.rawValue) {
                        Task {
                            do {
                                try await Sheets.shared.format(wrap:wrap, sheets: Case.Sheet.allCases.map(\.intValue), in: aCaseID)
                            } catch {
                                print("Error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
            Menu("Vertical") {
                ForEach(Sheets.Vertical.allCases, id:\.self) { vert in
                    Button(vert.rawValue) {
                        Task {
                            do {
                                try await Sheets.shared.format(vertical: vert, sheets: Case.Sheet.allCases.map(\.intValue), in: aCaseID)
                            } catch {
                                print("Error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
            Menu("Horizontal") {
                ForEach(Sheets.Horizontal.allCases, id:\.self) { hor in
                    Button(hor.rawValue) {
                        Task {
                            do {
                                try await Sheets.shared.format(horizontal: hor, sheets: Case.Sheet.allCases.map(\.intValue), in: aCaseID)
                            } catch {
                                print("Error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
            Divider()
            Button("Default") {
                Task {
                    do {
                        try await Sheets.shared.format(wrap:.clip,vertical: .top, horizontal: .left, sheets: Case.Sheet.allCases.map(\.intValue), in: aCaseID)
                    } catch {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    @ViewBuilder func caseView(_ aCaseID:String) -> some View {
        if let aCase = Bindable(delegate).cases.first(where: {$0.id == aCaseID}) {
            CaseView(aCase: aCase)
                .navigationTitle(aCase.wrappedValue.title)
            #if os(macOS)
                .navigationSubtitle(aCase.wrappedValue.category.title)
            #endif
        } else {
            Text("Could not locate case with id: \(aCaseID)")
        }
    }
    @ViewBuilder var spreadsheetView : some View {
        if let aCase = delegate[navModel.caseID] {
            DriveFileView([aCase.file], isLoading: true, isPreview: false)
                .navigationTitle("Cases")
                #if os(macOS)
                .navigationSubtitle(aCase.title)
                #endif
        } else {
            Text("Could not locate case with id: \(String(describing: navModel.caseID))")
        }
    }
}

//MARK: - Preview
#Preview {
    Cases_Content()
        .environment(CasesDelegate())
}
