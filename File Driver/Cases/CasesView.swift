//
//  CasesView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import SwiftUI
import BOF_SecretSauce


struct CasesView: View {
    @State private var cases : [Case] = []
//    @State private var selectedCaseID : Case.ID?
    @State private var scrollToCaseID : Case.ID?
    @State private var showNewCaseSheet = false
    @State private var editCase   : Case?
    @State private var filter = Filter()
    @AppStorage(BOF_Settings.Key.casesSort.rawValue) var sortBy : Case.SortBy = .category

    @State private var loader = VLoader_Item()
    @Environment(BOF_Nav.self) var navModel
    
   
    var body: some View {
        VStackLoacker(loader: $loader) {
            Task { await loadCases() }
        } content: {
            if cases.isEmpty {
                noCasesView
            } else {
                NavigationStack(path:Bindable(navModel).path) {
                    theListView
                        .padding(.top)
                        .contextMenu(forSelectionType: Case.ID.self,
                                                 menu: { listMenu($0 )         },
                                     primaryAction: { ids in
                            if let id = ids.first {
                                print("\(id)")
                                navModel.path.append(id)
                            }
                        })
                        .navigationDestination(for: Case.ID.self) { caseID in
                            if let index = index(for:caseID) {
                                CaseView(aCase: $cases[index])
                                    .navigationTitle(cases[index].title)
                                #if os(macOS)
                                    .navigationSubtitle(cases[index].category.title)
                                #endif
                            } else {
                                Text("Could not locate case with id: \(caseID)")
                            }
                        }
                }
            }
        }
            .task { await loadCases() }
            .onChange(of: cases, { _, _ in loadFilter() })
            .sheet(isPresented: $showNewCaseSheet) {
                NewCase { newCase in
                    cases.append(newCase)
                    navModel.caseID  = newCase.id
                    scrollToCaseID   = newCase.id
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
                        if let selectedCaseID = navModel.caseID, let index = index(for: selectedCaseID) {
                            editCase = cases[index]
                        }
                    }
                        .disabled(navModel.caseID == nil)
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
            loader.status = "Loading Cases"
            loader.start()
            cases = try await Case.allCases()
            loader.stop()
        } catch {
            loader.stop(error)
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
                List(selection: Bindable(navModel).caseID) {
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


