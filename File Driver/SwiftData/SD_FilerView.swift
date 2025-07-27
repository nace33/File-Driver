//
//  SD_FilerView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/24/25.
//

import SwiftUI
import SwiftData


struct SD_FilerView: View {
    @Query(sort: \FilerCase.name)   var cases: [FilerCase]
    @Query(sort: \FilerSearchString.text)   var searchStrings: [FilerSearchString]
    @State private var selectedCase: FilerCase?
    @State private var selectedSearchString: FilerSearchString?
    @Environment(\.modelContext) var context
    @State private var loader = VLoader_Item(isLoading: false)
    
    @State private var viewIndex : ViewIndex = .cases
    
    enum ViewIndex : String, CaseIterable{ case cases, words }
    
    var body: some View {
        VStackLoacker(loader: $loader) {
            loader.clearError()
        } content: {
            HSplitView {
                switch viewIndex {
                case .cases:
                    List(selection: $selectedCase) {
                        if cases.isEmpty {
                            Text("No Cases Found").foregroundStyle(.secondary)
                        }
                        ForEach(cases, id:\.self) { aCase in
                            Text(aCase.name)
                                .contextMenu {
                                    Button("Rebuild") { rebuild(aCase) }
                                    Divider()
                                    Button("Delete")  { delete(aCase) }
                                }
                        }
                            .listRowSeparator(.hidden)
                    }
                        .frame(minWidth:150, maxWidth:250)
                case .words:
                    List(selection: $selectedSearchString) {
                        if searchStrings.isEmpty {
                            Text("No Search Strings").foregroundStyle(.secondary)
                        }
                        ForEach(FilerSearchString.Category.allCases, id:\.self) { category in
                            let strings = searchStrings.filter { $0.intValue == category.rawValue }
                            if strings.count > 0 {
                                Section(category.title) {
                                    ForEach(strings, id:\.self) { str in
                                        Text(str.text)
                                    }
                                }
                            }
                        }
                     
                            .listRowSeparator(.hidden)
                    }
                        .frame(minWidth:150, maxWidth:250)
                }

             
                VStack {
                    if let selectedCase {
                        SD_FilerFoldersView(folders: selectedCase.folders)
                    }
                    else if let selectedSearchString {
                        SD_FilerFoldersView(folders: selectedSearchString.folders)
                    }
                    else {
                        ContentUnavailableView("No Selection", systemImage: "filemenu.and.selection")
                    }
                }
                    .frame(maxWidth:.infinity, maxHeight: .infinity)
                    .layoutPriority(1)
            }
        }


        .toolbar {
            ToolbarItem(placement:.navigation) {
                Picker("View", selection: $viewIndex) { ForEach(ViewIndex.allCases, id:\.self) { Text($0.rawValue)}}
                    .pickerStyle(.segmented)
                    .onChange(of: viewIndex) { oldValue, newValue in
                        selectedCase = nil
                        selectedSearchString = nil
                    }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Clear") {  clearDatabase(save:true) }
                Button("Rebuild") { Task { await rebuildDatabase() }}
            }
        }
        .disabled(loader.isLoading)
    }
    
    
    
    //MARK: - Delete
    func clearDatabase(save:Bool)  {
        do {
            selectedCase = nil
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
        if filerCase == selectedCase {
            selectedCase = nil
        }
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
        if filerCase == selectedCase {
            selectedCase = nil
        }
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


//MARK: - Cases
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
