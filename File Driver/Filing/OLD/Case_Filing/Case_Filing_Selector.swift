//
//  Case.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//

import SwiftUI


struct Case_Filing_Selector : View {
    @State private var error: Error?
    @State private var isLoading = true
    @State private var selectedCaseID : Case.ID?
    @State private var cases : [Case] = []
    @State private var categories : [Case.DriveLabel.Label.Field.Category] = []
    @State private var statuses   : [Case.DriveLabel.Label.Field.Status] = []
    @State private var status = ""
    @State private var filter = ""
    @State private var tokens : [Token] = []
    @State private var showFilterPopover = false
    @AppStorage(BOF_Settings.Key.casesFilingSortKey.rawValue)             var viewIndex        : ViewIndex = .type
    @AppStorage(BOF_Settings.Key.casesFilingFilterClosedKey.rawValue)     var filterClosed     : Bool = false
    @AppStorage(BOF_Settings.Key.caseFilingShowStatusColorsKey.rawValue)  var showStatusColors : Bool = true
    @AppStorage(BOF_Settings.Key.casesFilingShowSeetingsKey.rawValue)     var showSettings     : Bool = true
    
    enum ViewIndex : String, CaseIterable, Codable { case title, type, status }
    
    var body: some View {
        VStackLoader(spacing:0, title: "", isLoading: $isLoading, status: $status, error: $error) {
            NavigationStack {
                list
                    .listStyle(.sidebar)
                    .searchable(text: $filter,
                                tokens: $tokens,
                                placement: .sidebar,
                                prompt: Text("Type to filter, or use #, $ for tags")) { token in
                                Text(token.title)
                            }
                    .searchSuggestions {
                        if let tokenPrefix {
                            ForEach(tokenSuggestions) { token in
                                Text(token.title)
                                    .searchCompletion(tokenPrefix+token.title)
                            }
                        }
                    }
                    .onChange(of: filter) { _, newValue in
                        if newValue.starts(with: "#") || newValue.starts(with:"$") { checkShouldInsertToken() }
                    }
     
                    .contextMenu {   listMenu(inPopover: false)  }
                    .navigationTitle("Select a Case")
                    .navigationDestination(for: Case.self) { aCase in Case_Filing_DetailView(aCase)}
            }
        }
            .task { await fetchCases()}
            .frame(maxHeight: .infinity)
    }


    
    func fetchCases() async  {
        do {
            self.status = "Loading Cases"
            isLoading = true
            let caseLabelID = Case.DriveLabel.Label.id.rawValue
            let caseSpreadsheets = try await Google_Drive.shared.get(filesWithLabelID:caseLabelID)
                                                                .sorted(by: {$0.title.lowercased() < $1.title.lowercased()})
            cases = caseSpreadsheets.compactMap { Case($0)}
                                    .sorted(by: {$0.title.lowercased() < $1.title.lowercased()})
            
            categories = cases.compactMap { $0.driveLabel.category}
                              .unique()
                              .sorted(by: {$0.intValue < $1.intValue})

            statuses = cases.compactMap { $0.driveLabel.status}
                            .unique()
                            .sorted(by: {$0.intValue < $1.intValue})
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
        }
    }
}

//MARK: -View Builders
fileprivate extension Case_Filing_Selector {
    @ViewBuilder var list : some View {
        let filteredCases = self.filteredCases
        switch viewIndex {
        case .title:
            alphabeticList(filteredCases)
        case .type:
            categoryList(filteredCases)
        case .status:
            statusList(filteredCases)
        }
    }
    
    //Sub-List Views
    @ViewBuilder func alphabeticList(_ filteredCases: [Case]) -> some View {
        List(selection:$selectedCaseID) {
            caseSuggestions()
            filterView(filteredCount: filteredCases.count)
            ForEach(filteredCases) { aCase in
                row(aCase)
            }
        }
    }
    @ViewBuilder func categoryList(_ filteredCases: [Case]) -> some View {
        List(selection:$selectedCaseID) {
            filterView(filteredCount: filteredCases.count)
            caseSuggestions()

            ForEach(categories, id:\.self) { category in
                let casesInCategory = filteredCases.filter { $0.driveLabel.category == category}
                if casesInCategory.isNotEmpty {
                    Section(category.title.uppercased()) {
                        ForEach(casesInCategory) { aCase in
                            row(aCase)
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder func statusList(_ filteredCases: [Case]) -> some View {
        List(selection:$selectedCaseID) {
            filterView(filteredCount: filteredCases.count)
            caseSuggestions()
            ForEach(statuses, id:\.self) { status in
                let statusesInCategory = filteredCases.filter { $0.driveLabel.status == status}
                if statusesInCategory.isNotEmpty {
                    Section {
                        ForEach(statusesInCategory) { aCase in
                            row(aCase)
                        }
                    } header : {
                        Text(status.title.uppercased())
                            .foregroundStyle(showStatusColors ? status.color : .primary)
                    }
                }
            }
        }
    }
    @ViewBuilder func listMenu(inPopover:Bool) -> some View {
        Picker("Sort by", selection: $viewIndex) { ForEach(ViewIndex.allCases, id:\.self) { Text($0.rawValue.camelCaseToWords())}}
        Toggle("Filter Closed Cases", isOn: $filterClosed)
        Toggle("Show Case Status Colors", isOn: $showStatusColors)
        if !inPopover {
            Toggle("Show Filter In Table", isOn: $showSettings)
        }
        
    }
    
    //Case Suggestions
    @ViewBuilder func caseSuggestions() -> some View {
        EmptyView()
//        if isLoading { EmptyView() }
//        else {
//            Section {
//                HStack {
//                    Spacer()
//                    Text("Suggested cases to file to go here ...")
//                        .font(.caption)
//                        .foregroundStyle(.blue)
//                }
//                
//            }
//        }
    }
    
    //List Rows
    @ViewBuilder func row(_ aCase:Case) -> some View {
        NavigationLink(value: aCase) {
            Text(aCase.title)
                .foregroundStyle((viewIndex != .status && showStatusColors) ? aCase.driveLabel.status.color : .primary)
        }.contextMenu { rowMenu(aCase)}
    }
    @ViewBuilder func rowMenu(_ aCase:Case) -> some View {
        Text("Type:\t\(aCase.driveLabel.category.title)")
        Text("Status:\t\(aCase.driveLabel.status.title)")
        Text("Opened:\t\(aCase.driveLabel.opened.mmddyyyy)")
        if let closed = aCase.driveLabel.closed {
            Text("Closed:\t\(closed.mmddyyyy)")
        }
    }

}


//MARK: -Search & Tokens
fileprivate extension Case_Filing_Selector {
    struct Token : Identifiable, Hashable {
        let id : String
        let title : String
        let rawValue : String
        let type  : TokenType
        init(category:Case.DriveLabel.Label.Field.Category) {
            self.id = UUID().uuidString
            self.title = category.title
            self.rawValue = category.rawValue
            self.type = .category
        }
        init(status:Case.DriveLabel.Label.Field.Status) {
            self.id = UUID().uuidString
            self.title = status.title
            self.rawValue = status.rawValue
            self.type = .status
        }
        enum TokenType : String, CaseIterable { case category, status }
    }
    var filteredCases : [Case] {
        cases.filter { aCase in
            if filterClosed, aCase.driveLabel.status == .closed { return false }
            if !filter.isEmpty, !hasTokenPrefix, !aCase.title.ciContain(filter)  { return false }
            if !tokens.isEmpty {
                for token in tokens {
                    switch token.type {
                    case .category:
                        if aCase.driveLabel.category.rawValue != token.rawValue { return false }
                    case .status:
                        if aCase.driveLabel.status.rawValue   != token.rawValue { return false }
                    }
                }
            }
            return true
        }
    }
    var hasTokenPrefix : Bool {
        guard filter.isEmpty == false else { return false }
        guard filter.hasPrefix("#") || filter.hasPrefix("$") else { return false }
        return true
    }
    var tokenPrefix: String? {
        guard hasTokenPrefix else { return nil }
        return String(filter.first!)
    }
    var tokenSuggestions : [Token] {
    guard hasTokenPrefix else { return [] }
    let tokenString = String(filter.dropFirst())
    
    if filter.hasPrefix("#") {
        guard !tokenString.isEmpty else { return categories.compactMap { Token(category:$0)} }
        return categories.compactMap {
            if $0.title.ciHasPrefix(tokenString) { return Token(category: $0) }
            else { return nil }
        }
    } else {
        guard !tokenString.isEmpty else { return statuses.compactMap { Token(status:$0)} }
        return statuses.compactMap {
            if $0.title.ciHasPrefix(tokenString) { return Token(status: $0) }
            else { return nil }
        }
    }
}
    func checkShouldInsertToken() {
        guard let tokenPrefix else { return }
        guard let suggestedToken = tokenSuggestions.first else { return }
        
        let value = String(filter.dropFirst())
        
        if value == suggestedToken.title {
            tokens.append(suggestedToken)
            filter = filter.replacingOccurrences(of: tokenPrefix+value, with: "")
        }
    }
}


fileprivate extension Case_Filing_Selector {
    var hasFilterApplied : Bool {
        guard filterClosed else {return false}
        return true
    }
    @ViewBuilder func filterView(filteredCount:Int) -> some View {
        if showSettings {
            HStack {
                Spacer()
                let hasFilterApplied = self.hasFilterApplied
                Button { showFilterPopover.toggle()} label: {
                    Image(systemName: "line.3.horizontal.decrease.circle\(hasFilterApplied ? ".fill" : "")" )
                }
                .buttonStyle(.plain)
                .foregroundStyle(hasFilterApplied ? .blue.opacity(0.5) : .secondary )
                .popover(isPresented:$showFilterPopover, arrowEdge: .bottom) {
                    Form {
                        listMenu(inPopover: true)
                            .pickerStyle(.segmented)

                    }
                    .padding()
                }
            }
        }
    
    }
}
