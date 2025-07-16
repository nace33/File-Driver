//
//  struct BOF_SwiftDataView_Suggestions - View { .swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/30/25.
//

import SwiftUI
import SwiftData
import GoogleAPIClientForREST_Drive

struct BOF_SwiftDataView_Suggestions : View {

    @State private var isRebuilding = false
    @State private var error: Error?
    @State private var statusString = ""
    @State private var progress     : Float? = nil
    
    enum ViewType : String, CaseIterable { case cases, words  }
    @State private var viewType : ViewType = .cases
    
    @Query(sort: \WordSuggestion.text)   var words: [WordSuggestion]
    @Query(filter:#Predicate { $0.parent == nil }, sort: \FolderSuggestion.name) var folders: [FolderSuggestion]
    @State private var selectedFolder: FolderSuggestion?
    @State private var selectedSubFolder : FolderSuggestion?
    @State private var selectedWord  : WordSuggestion?
    @State private var filterText   : String = ""
    
    
    var body: some View {
        HSplitView {
            if let error {
                errorView(error)
            } else if isRebuilding {
                progressView
            }
            else if folders.isEmpty && words.isEmpty {
                emptyView
            }
            else {
                listView
                    .listStyle(.sidebar)
                    .frame(minWidth:250)
                    .searchable(text: $filterText, placement: .sidebar)
                detailView
                    .alternatingRowBackgrounds()
                    .layoutPriority(1)
                    .frame(minWidth: 250, maxWidth: .infinity, maxHeight: .infinity)
                    
                if let selectedSubFolder {
                    folderWordView(selectedSubFolder)
                        .layoutPriority(0)
                        .frame(minWidth: 150)
                }
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: selectedFolder, { oldValue, newValue in
                selectedSubFolder = nil
            })
            .onChange(of: viewType, { _, _ in
                selectedWord = nil
                selectedSubFolder = nil
                selectedFolder = nil
                filterText = ""
            })
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Picker("View", selection: $viewType) {
                        Text("Cases").tag(ViewType.cases)
                        Text("Words").tag(ViewType.words)
                    }
                        .pickerStyle(.segmented)
                    Menu("Actions") {
                        Button("Rebuild") {
                            Task { await rebuildAllFolders() }
                        }
                        Divider()
                        Button("Delete All") { try? clearDatabase()}
                            .disabled(folders.isEmpty && words.isEmpty)
                    }
                }
            }
            .disabled(isRebuilding)
    }
    
    var suggestions : Suggestions { Suggestions.shared}
}


//MARK: - Properties
extension BOF_SwiftDataView_Suggestions {
    var filteredFolders: [FolderSuggestion] {
        guard !filterText.isEmpty else { return folders }
        return folders.filter { $0.name.lowercased().contains(filterText.lowercased()) }
    }
    var filteredWords: [WordSuggestion] {
        guard !filterText.isEmpty else { return words }
        return words.filter { $0.text.lowercased().contains(filterText.lowercased()) }
    }
}


//MARK: - Actions
extension BOF_SwiftDataView_Suggestions {
    func clearDatabase() throws {
        do {
            try suggestions.deleteAllSuggestions()
        } catch {
            self.error = error
            throw error
        }
    }
    func rebuildAllFolders() async {
        do {
            try clearDatabase()
            isRebuilding = true
            statusString = "Fetching Cases"
            progress     = nil
            
            let cases = try await Drive.shared.get(filesWithLabelID:Case.DriveLabel.Label.id.rawValue)
                                              .sorted(by: {$0.title.lowercased() < $1.title.lowercased()})
                                              .compactMap { Case($0)}
            
            for (index, aCase) in cases.enumerated() {
                statusString = "Building \(aCase.title)"

                _ = try await suggestions.update(aCase, save:index == cases.count - 1)
                progress = Float(index + 1) / Float(cases.count)
            }
            
            statusString = "Rebuilding Complete!"
            isRebuilding = false
        } catch {
            isRebuilding = false
            self.error = error
        }
    }
    func rebuild(_ folder:FolderSuggestion) async {
        do {
            let caseFile        = GTLRDrive_File()
            caseFile.identifier = folder.id
            let caseLabel       = Case.DriveLabel(title: "", category: .miscellaneous, status: .active, opened: Date(), closed: nil, folderID: "")
            let caseSpreadsheet = Case(file: caseFile, label: caseLabel)
            folder.isSyncing = true
            _ = try await suggestions.update(caseSpreadsheet, save:true)
            folder.isSyncing = false
        } catch {
            folder.isSyncing = false
            self.error = error
        }
    }
}


//MARK: - View Builders
extension BOF_SwiftDataView_Suggestions {
    @ViewBuilder func errorView    (_ error:Error) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(error.localizedDescription)
                Button("Clear Error") { self.error = nil }
                Spacer()
            }
            Spacer()
        }
    }
    @ViewBuilder var  emptyView   : some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    Text("No Suggestions")
                        .font(.headline)
                    Text("This database is built as you use the Filer!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Spacer()
        }
    }
    @ViewBuilder var  progressView : some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ProgressView(statusString, value:progress)
                    .padding(40)
                Spacer()
            }
            Spacer()
        }
    }
    @ViewBuilder var  listView     : some View {
            switch viewType {
            case .cases:
                List(selection:$selectedFolder) {
                    ForEach(filteredFolders, id:\.self) { folder in
                        Label {
                            Text(folder.name)
                        } icon: {
                            if folder.isSyncing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.5)
                                    .frame(width:16, height:16)
                            } else {
                                Image(GTLRDrive_File.MimeType.sheet.title)
                                    .resizable()
                                    .frame(width:16, height:16)
                            }
                        }
                        .contextMenu {
                            Button("Re-Sync") { Task { await rebuild(folder)}}
                            Button("Clear") { try? suggestions.clearRelationships(folder)}
                                .modifierKeyAlternate(.command) {
                                    Button("Delete") { suggestions.context.delete(folder) }
                                }
                        }
                    }
                }
            case .words:
                List(selection:$selectedWord) {
                    ForEach(filteredWords, id:\.self) { word in
                        Text(word.text)
                            .foregroundStyle(word.isBlocked ? .red : .primary)
                            .contextMenu {
                                Button(word.isBlocked ? "Unblock" : "Block") { suggestions.toggleBlock(word)}
                                Button("Delete") { suggestions.context.delete(word) }
                            }
                    }
                }
            }
    }
    @ViewBuilder var  detailView   : some View {
        switch viewType {
        case .cases:
            List(selection:$selectedSubFolder) {
                if let selectedFolder {
                    if let folders = selectedFolder.children?.sorted(by: { $0.name < $1.name }), folders.isNotEmpty {
                        ForEach(folders, id:\.self) { folder in
                            Label {
                                Text(folder.name)
                            } icon: {
                                if folder.isSyncing {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.5)
                                        .frame(width:16, height:16)
                                } else {
                                    Image(GTLRDrive_File.MimeType.folder.title)
                                        .resizable()
                                        .frame(width:16, height:16)
                                }
                            }
                                .contextMenu {
                                    wordMenu(folder)
                                    Button("Delete") { suggestions.context.delete(folder)}
                                }
                        }
                            .listRowSeparator(.hidden)
                    }
                    else {
                        Text("No folders found")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No Selection")
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(selectedFolder?.isSyncing ?? false )
        case .words:
            List(selection:$selectedWord) {
                if let selectedWord {
                    if let folders = selectedWord.folders?.sorted(by: {$0.pathString < $1.pathString}) {
                        let cases = folders.compactMap { $0.root }.unique()
                        ForEach(cases) { aCase in
                            let caseFolders = folders.filter { $0.root === aCase }
                            Section(aCase.name) {
                                ForEach(caseFolders) { folder in
                                    Text(folder.name)
                                        .contextMenu {
                                            Button("Delete") { suggestions.context.delete(folder)}
                                        }
                                }
                            }
                        }
                            .listRowSeparator(.hidden)
                    }
                    else {
                        Text("Word not used in any cases.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No Selection")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    @ViewBuilder func wordMenu(_ folder:FolderSuggestion) -> some View {
        if let folderWords = folder.words, folderWords.count > 0  {
            Menu("Words") {
                ForEach(words.sorted(by: {$0.text < $1.text }), id:\.self) { word in
                    Text(word.text)
                }
            }
        }
    }
    @ViewBuilder func folderWordView(_ folder:FolderSuggestion) -> some View {
        List {
            if let folderWords = folder.words?.sorted(by: {$0.text < $1.text }), folderWords.count > 0  {
                Section("Words") {
                    ForEach(folderWords, id:\.self) { word in
                        Text(word.text)
                    }
                        .listRowSeparator(.hidden)
                }
            }
        }
    }
}

