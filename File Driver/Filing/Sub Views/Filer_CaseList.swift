//
//  Filer_CaseList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/21/25.
//

import SwiftUI
import SwiftData
import BOF_SecretSauce
import GoogleAPIClientForREST_Drive

struct Filer_CaseList: View {
    @Environment(Filer_Delegate.self) var delegate
    @Query private var folders: [FilerFolder]
    
    @State private var showCreateCaseSheet: Bool = false
    
    @State private var suggestions : [FilerSuggestion] = []
    @AppStorage(BOF_Settings.Key.filingAllowSuggestions.rawValue)          var allowSuggestions    : Bool = true
    @AppStorage(BOF_Settings.Key.filingSuggestionLimit.rawValue)           var suggestionLimit      : Int = 5
    var body: some View {
        ScrollViewReader { proxy in
            List(selection:Bindable(delegate).caseListSelection) {
          
                if delegate.caseCategories.isEmpty {
                    noCasesView
                        .listRowSeparator(.hidden)
                }
                else {
                    if allowSuggestions, suggestions.count > 0 {
                        suggestionsView
                    }
                    casesView
                        .listRowSeparator(.hidden)
                        .onChange(of: delegate.caseListScrollID) { _, newID in  proxy.scrollTo(newID)  }
#if os(macOS)
                        .alternatingRowBackgrounds()
                    #endif
                }
            }
            .contextMenu(forSelectionType: Case.self, menu: { items in
                if let item = items.first {
                    Button("Select Case") {
                        delegate.select(item)
                    }
                } }, primaryAction: { items in
                    if let item = items.first {
                        delegate.select(item)
                    }
                })
                .sheet(isPresented: $showCreateCaseSheet) {
                    NewCase { delegate.addNewCase($0)  }
                }
                .task(id:delegate.items) {
                    loadSuggestions()
                }
        }
    }
}


//MARK: - Case Actions
fileprivate extension Filer_CaseList {
    var filteredCases : [Case] {
        guard delegate.filterString.count > 0 else {return delegate.cases}
        return delegate.cases.filter { $0.title.ciContain(delegate.filterString)}
    }
    func casesInCategory(_ category: Case.DriveLabel.Label.Field.Category) -> [Case] {
        filteredCases.filter { $0.category == category }
    }
}


//MARK: - View Builders
fileprivate extension Filer_CaseList {
    ///Suggestions
    @ViewBuilder var suggestionsView  : some View {
        Section("Suggestions") {
            ForEach($suggestions, id:\.self) { $suggestion in
                HStack {
                    Text(suggestion.filerCase.name)
                        .contextMenu {
                            Button("Select Case") {
                                delegate.select(suggestion, presentFilingForm: false)
                            }
                        }
                    Spacer()
                    suggestionMenu(for:$suggestion)
                    Button("Select") {
                        delegate.select(suggestion, presentFilingForm: true)
                    }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                }
            }
        }
            .listRowSeparator(.hidden)
    }
    @ViewBuilder func suggestionMenu(for suggestion:Binding<FilerSuggestion>) -> some View {
        Menu {
            ForEach(suggestion.wrappedValue.sortedFolders) { folder in
                Menu(folder.name) {
                    Text("Last Used:\t\(folder.lastUsed, style: .date)")
                    Text("Times Used:\t\(folder.timesUsed)")
                    Text("Sort Value:\t\(suggestion.wrappedValue.intValue(for:folder))")
                    Divider()
                    
                    let strings = suggestion.wrappedValue.strings(for:folder)
                   
                    ForEach(FilerSearchString.Category.allCases.sorted(by: {$0.rawValue > $1.rawValue}), id:\.self) { category in
                        let catStrings = strings.filter { $0.intValue == category.rawValue }
                                                .sorted(by:{ $0.text < $1.text })
                        if catStrings.count > 0 {
                            if strings.count > 8 {
                                Menu(category.title) {
                                    ForEach(catStrings, id:\.text) { catString in
                                        Text(catString.text)
                                    }
                                }
                            } else {
                                ForEach(catStrings, id:\.text) { catString in
                                    Text(catString.text)
                                }
                            }
 
                        }
                    }
//                    Button("Select") {
//                        suggestion.wrappedValue.selectedFolder = folder
//                        delegate.select(suggestion.wrappedValue, presentFilingForm: true)
//                    }
                } primaryAction: {
                    suggestion.wrappedValue.selectedFolder = folder
                }
            }
        } label: {
            Text(suggestion.wrappedValue.selectedFolder.name)
        }
            .fixedSize()
    }
    
    ///Cases
    @ViewBuilder var noCasesView: some View {
        Text("No Cases Found").foregroundStyle(.secondary)
        Button("Create Case") { showCreateCaseSheet = true }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
    }
    @ViewBuilder var casesView: some View {
        ForEach(delegate.caseCategories, id:\.self) { category in
            let casesInCategory = casesInCategory(category)
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
    }
}


//MARK: - Suggestion Actions
fileprivate extension Filer_CaseList {
    func loadSuggestions() {
  
        suggestions.removeAll()
        
        var searchWords : Set<String> = []
        for item in delegate.items {
            searchWords.formUnion(item.lowercasedSearchWords)
        }
        searchWords = FilerBlockText.subtractBlockedWords(searchWords)
 
        
        let searchStrings = FilerSearchString.search(strings: searchWords, category: nil) ?? []
  
        for searchString in searchStrings {
            for searchFolder in searchString.folders ?? [] {
                if let aCase = searchFolder.aCase, delegate.cases.first(where: {$0.id == aCase.spreadsheetID}) != nil {
                    if let index = suggestions.firstIndex(where: {$0.filerCase.spreadsheetID == aCase.spreadsheetID}) {
                        suggestions[index].filerFolders.insert(searchFolder)
                        suggestions[index].filerStrings.insert(searchString)
                    } else {
                        suggestions.append(.init(filerCase: aCase, filerFolder: searchFolder, filerString: searchString))
                    }
                }
            }
        }
        
        suggestions.sort(by: {$0.intValue > $1.intValue })
        for (index, suggestion) in self.suggestions.enumerated() {
            if let first = suggestion.sortedFolders.first  {
                suggestions[index].selectedFolder = first
            }
        }
        if suggestions.count > suggestionLimit {
            while suggestions.count > suggestionLimit {
                suggestions = suggestions.dropLast()
            }
        }
    }
    func hasSuggestion(for aCase:Case) -> Bool {
        suggestions.first(where: {$0.filerCase.spreadsheetID == aCase.id}) != nil
    }
}

struct FilerSuggestion : Identifiable, Hashable {
    var id           : String
    let filerCase    : FilerCase
    var selectedFolder : FilerFolder
    var filerFolders : Set<FilerFolder>
    var filerStrings : Set<FilerSearchString>
    var intValue     : Int {
        filerStrings.map(\.intValue).reduce(0, +)
    }
    
    init(filerCase: FilerCase, filerFolder:FilerFolder, filerString: FilerSearchString) {
        self.id = UUID().uuidString
        self.filerCase = filerCase
        self.filerFolders = [filerFolder]
        self.filerStrings = [filerString]
        self.selectedFolder = filerFolder
    }
    
    var sortedFolders : [FilerFolder] {
        filerFolders.sorted { lhs, rhs in
            let lhsValue   = intValue(for: lhs)
            let rhsValue   = intValue(for: rhs)
            if lhsValue != rhsValue {
                return lhsValue > rhsValue
            } else {
                if abs(lhs.timesUsed - rhs.timesUsed) > 5 {
                    return lhs.timesUsed > rhs.timesUsed
                } else {
                    return lhs.lastUsed > rhs.lastUsed
                }
            }
        }
    }
    
    var sortedStrings : [FilerSearchString] {
        filerStrings.sorted { lhs, rhs in
            lhs.text < rhs.text
        }
    }
    func intValue(for folder:FilerFolder) -> Int{
        strings(for: folder).map(\.intValue).reduce(0, +)
    }
    func strings(for folder:FilerFolder) -> [FilerSearchString] {
        filerStrings.filter { $0.folders?.contains(folder) ?? false}
    }
}


