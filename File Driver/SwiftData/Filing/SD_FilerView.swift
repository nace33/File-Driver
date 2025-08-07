//
//  SD_FilerView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/24/25.
//

import SwiftUI
import SwiftData


struct SD_FilerView: View {
//    @Query(sort: \FilerCase.name)   var cases: [FilerCase]
//    @Query(sort: \FilerSearchString.text)   var searchStrings: [FilerSearchString]
//    @Query var blockedWords: [FilerBlockText]
//    @State private var selectedCase: FilerCase?
//    @State private var selectedSearchString: FilerSearchString?
//    @State private var selectedBlockedText: FilerBlockText?
    @Environment(\.modelContext) var context
    @State private var loader = VLoader_Item(isLoading: false)
    
    @State private var viewIndex : ViewIndex = .suggestions
    
    enum ViewIndex : String, CaseIterable{ case cases, suggestions }
    
    var body: some View {
        VStackLoacker(loader: $loader) {
            loader.clearError()
        } content: {
            switch viewIndex {
            case .cases:
                SD_Filer_CasesView()
                    .contextMenu(forSelectionType: FilerCase.self) { rightClickCases($0) }
            case .suggestions:
                SD_Filer_SearchStringsView()
            }
        }


        .toolbar {
            ToolbarItem(placement:.navigation) {
                Picker("View", selection: $viewIndex) { ForEach(ViewIndex.allCases, id:\.self) { Text($0.rawValue.capitalized)}}
                    .pickerStyle(.segmented)
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Clear") {  clearDatabase(save:true) }
                Button("Rebuild") { Task { await rebuildDatabase() }}
            }
        }
        .disabled(loader.isLoading)
    }
    
    //MARK: - Right Click
    @ViewBuilder func rightClickCases(_ items:Set<FilerCase>) -> some View {
        if let first = items.first {
            Button("Rebuild") { rebuild(first) }
            Divider()
            Button("Delete")  { delete(first) }
        }
    }

    
    
    //MARK: - Delete
    func clearDatabase(save:Bool)  {
        do {
            loader.status = "Clearing Database"
            loader.start()
            try context.delete(model:FilerCase.self)
            try context.delete(model:FilerSearchString.self)
            if save {
                try context.save()
            }
            loader.stop()
        } catch {
            loader.stop(error)
        }
    }
    func delete(_ filerCase:FilerCase) {
        context.delete(filerCase)
    }
    
    
    //MARK: - Rebuild
    func rebuild(_ aCase:Case, save:Bool) async throws {
        do {
            loader.start()
            loader.status = "Loading \(aCase.title)"
            try await aCase.load(sheets: [.contacts, .contactData, .folders, .tags, .files])
            let newFilerCase = FilerCase.rebuild(aCase)
             context.insert(newFilerCase)
            
            if save {
                try? context.save()
            }
            loader.stop()
        } catch {
            loader.stop(error)
            throw error
        }
    }
    func rebuild(_ filerCase:FilerCase) {
  
        Task {
            do {
                loader.start()
                loader.status = "Loading \(filerCase.name)"
                let foundCase = try await Case.getCase(id: filerCase.spreadsheetID)
                delete(filerCase)
                try await rebuild(foundCase, save:true)
                loader.stop()
            } catch {
                loader.stop(error)
            }
        }
    }
    func rebuildDatabase() async {
        do {
            clearDatabase(save: false)
            loader.status = "Loading Cases"
            loader.start()
            let allCases = try await Case.allCases()
            for (index, aCase) in allCases.enumerated() {
                loader.progress = Double(index) / Double(allCases.count)
                let isLast = index == (allCases.count - 1)
                try await rebuild(aCase, save:isLast)
            }
            loader.stop()
        } catch {
            loader.stop(error)
        }
    }
}

/*
//MARK: - Word List
fileprivate struct SD_FilerWordList : View {
    @Binding var selectedSearchString : FilerSearchString?
    let searchStrings : [FilerSearchString]
    @Query var blockedWords: [FilerBlockText]
    @State private var filter = ""

   
    func isBlocked(_ string:FilerSearchString) -> Bool {
        blockedWords.filter ( { block in
            block.isBlocked(string.text)
        })
            .count > 0
    }
    var filteredWords: [FilerSearchString] {
        guard !filter.isEmpty else {
            return searchStrings
        }
        return searchStrings.filter {
            $0.text.lowercased().contains(filter.lowercased())
        }
    }
    var body: some View {
        List(selection: $selectedSearchString) {
            if searchStrings.isEmpty {
                Text("No Search Strings").foregroundStyle(.secondary)
            }
            ForEach(FilerSearchString.Category.allCases, id:\.self) { category in
                let strings = filteredWords.filter { $0.intValue == category.rawValue }
                if strings.count > 0 {
                    Section(category.title) {
                        ForEach(strings, id:\.self) { str in
                            Text(str.text)
                                .foregroundStyle(isBlocked(str) ? .red : .primary)
                        }
                    }
                }
            }
         
                .listRowSeparator(.hidden)
        }
        .listStyle(.sidebar)
        .searchable(text: $filter, placement: .sidebar)
    }
}

//MARK: - Case List
fileprivate struct SD_FilerCaseList : View {
    @Binding var selectedCase : FilerCase?
    let cases : [FilerCase]
    @State private var filter = ""
    var filteredCases : [FilerCase] {
        guard !filter.isEmpty else {
            return cases
        }
        return cases.filter {
            $0.name.lowercased().contains(filter.lowercased())
        }
    }
    var body: some View {
        List(selection: $selectedCase) {
            if cases.isEmpty {
                Text("No Cases Found").foregroundStyle(.secondary)
            }
            ForEach(filteredCases, id:\.self) { aCase in
                Text(aCase.name)
            }
                .listRowSeparator(.hidden)
        }
        .listStyle(.sidebar)
        .searchable(text: $filter, placement: .sidebar)
    }
}

//MARK: - Blocked List
fileprivate struct SD_FilerBlockedList : View {
    @Binding var selectedBlockedText : FilerBlockText?
    let blockedWords : [FilerBlockText]
    @State private var filter = ""
    var filteredBlocked : [FilerBlockText] {
        guard !filter.isEmpty else {
            return blockedWords
        }
        return blockedWords.filter {
            $0.text.lowercased().contains(filter.lowercased())
        }
    }
    var body: some View {
        List(selection: $selectedBlockedText) {
            if blockedWords.isEmpty {
                Text("No Cases Found").foregroundStyle(.secondary)
            }
            ForEach(filteredBlocked, id:\.self) { aCase in
                Text(aCase.text)
            }
                .listRowSeparator(.hidden)
        }
        .listStyle(.sidebar)
        .searchable(text: $filter, placement: .sidebar)
    }
}
fileprivate struct SD_FilerBlockedTextView : View {
    let blockedText : FilerBlockText
    let searchStrings : [FilerSearchString]
    func isBlocked(_ string:FilerSearchString) -> Bool {
        blockedText.isBlocked(string.text)
    }
    var body: some View {
        List {
            ForEach(searchStrings.filter({isBlocked($0)})) { searchString in
                Text(searchString.text)
            }
        }
    }
}


//MARK: - Case View
fileprivate struct SD_FilerCaseView : View {
    let filerCase : FilerCase
    @State private var selectedFolder :FilerFolder?
    @Environment(\.modelContext) var context

    var body: some View {
        List(selection:$selectedFolder) {
            if let folders = filerCase.folders {
                Section("Folders") {
                    ForEach(folders, id:\.self) { folder in
                        Text(folder.name)
                            .contextMenu {
                                Button("Delete") { context.delete(folder) }
                            }
                    }
                }
                .listRowSeparator(.hidden)
            } else {
                Text("No folders").foregroundStyle(.secondary)
            }
        }
        .alternatingRowBackgrounds()
            .inspector(isPresented: .constant(selectedFolder != nil)) {
                if let selectedFolder {
                    SD_FilerFolderView(filerFolder: selectedFolder)
                        .inspectorColumnWidth(300)
                }
            }
        
    }
}

//MARK: - Folders View
fileprivate struct SD_FilerFoldersView : View {
    let folders : [FilerFolder]?
    @State private var selectedFolder :FilerFolder?
    @Environment(\.modelContext) var context

    var body: some View {
        List(selection:$selectedFolder) {
            if let folders = folders {
                Section("Folders") {
                    ForEach(folders, id:\.self) { folder in
                        Text(folder.name)
                            .contextMenu {
                                Button("Delete") { context.delete(folder) }
                            }
                    }
                }
                .listRowSeparator(.hidden)
            } else {
                Text("No folders").foregroundStyle(.secondary)
            }
        }
        .alternatingRowBackgrounds()
            .inspector(isPresented: .constant(selectedFolder != nil)) {
                if let selectedFolder {
                    SD_FilerFolderView(filerFolder: selectedFolder)
                        .inspectorColumnWidth(300)
                }
            }
        
    }
}

//MARK: - Folders
fileprivate struct SD_FilerFolderView : View {
    let filerFolder : FilerFolder
    @Environment(\.modelContext) var context
    @Query var blockedWords: [FilerBlockText]
 
   
    func isBlocked(_ string:FilerSearchString) -> Bool {
        blockedWords.filter ( { block in
            block.isBlocked(string.text)
        })
            .count > 0
    }
    

    var body: some View {
        List {
            ForEach(FilerSearchString.Category.allCases, id:\.self) { category in
                if let items = filerFolder.searchStrings?.filter({$0.category == category }), items.count > 0 {
                    Section(category.title) {
                        ForEach(items) { row in
                            Text(row.text)
                                .foregroundStyle(isBlocked(row) ? .red : .primary)
                                .contextMenu {
                                    Text(row.itemID)
                                    Button("Delete") { context.delete(row) }
                                }
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
    }
}



#Preview {
    @Previewable @State var sd = BOF_SwiftData.shared
    SD_FilerView()
        .environment(Google.shared)
        .modelContainer(sd.container)
}
*/
