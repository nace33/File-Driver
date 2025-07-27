//
//  CasesView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import SwiftUI
import BOF_SecretSauce


struct CasesView: View {
    @State private var isLoading = false
    @State private var cases : [Case] = []
    @State private var error: Error?
    @State private var selectedCaseID : Case.ID?
    @State private var scrollToCaseID : Case.ID?
    @State private var showNewCaseSheet = false
    @State private var editCase   : Case?
    @State private var filter = Filter()
    @AppStorage(BOF_Settings.Key.casesSort.rawValue) var sortBy : Case.SortBy = .category


    var body: some View {
        HSplitView {
            if let error {
                errorView(error)
            }
            else if isLoading {
                loadingView
            }
            else if cases.isEmpty {
                noCasesView
            }
            else {
                theListView
                    .alternatingRowBackgrounds()
                    .frame(minWidth:400, idealWidth: 400, maxWidth: 400)
                    .contextMenu(forSelectionType: Case.ID.self,
                                             menu: { listMenu($0 )         },
                                    primaryAction: { _ in print("Double Click") })
                
                Group {
                    if let index = index(for: selectedCaseID) {
                        VStack {
                            Text("Case Detail Here \(index)")
                            Text("Option to audit case files")
                            Text("Audit means iterating each file found in CaseFile.folder and comparing it to the Case.File sheet.")
                        }
                    } else {
                        ContentUnavailableView("No Selection", systemImage: "filemenu.and.selection", description: Text("Select a case from the list on the left."))
                    }
                }
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
            .task { await loadCases() }
            .onChange(of: cases, { _, _ in loadFilter() })
            .sheet(isPresented: $showNewCaseSheet) {
                NewCase { newCase in
                    cases.append(newCase)
                    selectedCaseID = newCase.id
                    scrollToCaseID = newCase.id
                }
            }
            .sheet(item: $editCase) { aCase in
                if let index = index(for: aCase.id) {
                    EditCase($cases[index])
                } else {
                    Form {
                        Text("Could not find case to edit")
                        Button("Close") { editCase = nil}
                    }.padding()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button { Task { await loadCases() }} label: {Image(systemName: "arrow.clockwise")}
                    Button("New") {  showNewCaseSheet = true }
                    Button("Edit") {
                        if let selectedCaseID, let index = index(for: selectedCaseID) {
                            editCase = cases[index]
                        }
                    }
                        .disabled(selectedCaseID == nil)
                }
            }
    }
}


//MARK: - Properties
extension CasesView {
    var filteredCases :[Case] {
        cases.filter { aCase in
            if !filter.string.isEmpty, !filter.hasTokenPrefix, !aCase.title.ciContain(filter.string) { return false   }
            if !filter.tokens.isEmpty {
                for token in filter.tokens {
                    if token.prefix == .hashTag {
                        if aCase.category.rawValue   != token.rawValue { return false }
                    }
                    else if token.prefix == .dollarSign {
                        if aCase.status.rawValue != token.rawValue { return false }
                    } 
                }
            }
            return true
        }
    }
    var sortKey : KeyPath<Case,String> {
        switch sortBy {
        case .category:
            \.label.category.title
        case .status:
            \.label.status.title
        case .name:
            \.label.title
        }
    }
    var isAlphabetic : Bool {
        sortBy == .name
    }
}


//MARK: - Actions
extension CasesView {
    func index(for aCaseID:Case.ID?) -> Int? {
        guard let aCaseID else { return nil }
        return cases.firstIndex(where: {$0.id == aCaseID })
    }
    func loadCases() async {
        do {
            isLoading = true
            cases = try await Case.allCases()
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
        }
    }
    func loadFilter() {
        let hashTags    = Case.DriveLabel.Label.Field.Category.allCases.compactMap { Filter.Token(prefix: .hashTag, title: $0.title, rawValue: $0.rawValue)  }
        let dollarSigns = Case.DriveLabel.Label.Field.Status.allCases.compactMap { Filter.Token(prefix: .dollarSign, title: $0.title, rawValue: $0.rawValue)  }
        filter.allTokens = hashTags + dollarSigns
    }
}


//MARK: - View Builders
extension CasesView {
    @ViewBuilder func errorView(_ error:Error) -> some View {
        VStack {
            Spacer()
            HStack {
                Text(error.localizedDescription)
                Button("Reload Cases") { Task { await loadCases() }}
            }
            Spacer()
        }
    }
    @ViewBuilder var noCasesView : some View {
        VStack {
            Spacer()
            Text("Create your first Case!")
//            newMenu
            Spacer()
        }
    }
    @ViewBuilder var emptyFilteredCasesView : some View {
        if filter.isEmpty {
            Menu {
                
            } label: {
                Text("- \(cases.count ) contacts are hidden -")
                    .foregroundStyle(.blue)
            }
                .fixedSize()
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
        } else {
            Text("No Cases")
                .foregroundStyle(.secondary)
        }
    }
    @ViewBuilder var loadingView  : some View {
        VStack {
            Spacer()
            ProgressView("Loading Cases")
            Spacer()
        }
    }
    @ViewBuilder var theListView: some View {
        VStack(spacing:0) {
            let filteredCases = filteredCases
            ScrollViewReader { proxy in
                List(selection: $selectedCaseID) {
                    if filteredCases.isEmpty {  emptyFilteredCasesView }
                    
                    BOFSections(of: filteredCases, groupedBy:sortKey, isAlphabetic: isAlphabetic) { headerText in
                        Text(headerText.uppercased())
                    } row: { aCase in
                        Text(aCase.title)
                    }
                        .listRowSeparator(.hidden)
                 
                }
                    .onChange(of: scrollToCaseID) { _, newID in  proxy.scrollTo(newID)  }
                    .listStyle(.sidebar)
                    .searchable(text:   $filter.string,
                                tokens: $filter.tokens,
                                placement:.sidebar,
                                prompt: Text("Type to filter, or use #, $ for tags")) { token in
                        Text(token.title)
                    }
                    .searchSuggestions { filter.searchSuggestions }
            }
            CasesFilter(count:filteredCases.count)
        }
    }
    @ViewBuilder func listMenu(_ caseIDs:Set<Case.ID>) -> some View {
        if let aCaseID = caseIDs.first, let index = index(for:aCaseID) {
            Button("Edit") { editCase = cases[index] }
            Menu("Info") {
                Text("Type\t"   + cases[index].category.title)
                Text("Status\t" + cases[index].status.title)
                Text("Opened\t" + cases[index].opened.mmddyyyy)
                if cases[index].status == .closed, let closed = cases[index].closed {
                    Text("Closed\t\(closed.mmddyyyy)")
                }
            }
            SidebarItemToggleButton(url: cases[index].file.url, category: .aCase, title: cases[index].title)
        }
    }

}


//MARK: - Preview
#Preview {
    CasesView()
        .frame(minWidth:800, minHeight: 600)
        .environment(Google.shared)
}


