//
//  SD_Filer_Words.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/29/25.
//

import SwiftUI
import SwiftData

struct SD_Filer_SearchStringsView: View {
    @Query(sort: \FilerSearchString.text)   var searchStrings: [FilerSearchString]
    @State private var selected: FilerSearchString?
    @State private var filter = ""

    var filteredWords: [FilerSearchString] {
        guard !filter.isEmpty else {
            return searchStrings
        }
        return searchStrings.filter {
            $0.text.lowercased().contains(filter.lowercased())
        }
    }
    var body: some View {
        HSplitView {
            List(selection: $selected) {
                if searchStrings.isEmpty {
                    Text("No Search Strings").foregroundStyle(.secondary)
                }
                ForEach(FilerSearchString.Category.allCases, id:\.self) { category in
                    let strings = filteredWords.filter { $0.intValue == category.rawValue }
                    if strings.count > 0 {
                        Section(category.title) {
                            ForEach(strings, id:\.self) { str in
                                SD_Filer_SearchStringRow(searchString: str)
                            }
                        }
                    }
                }
                
                .listRowSeparator(.hidden)
            }
                .listStyle(.sidebar)
                .searchable(text: $filter, placement: .sidebar)
                .frame(minWidth:150, maxWidth:250)

            
            VStack {
                if let selected {
                    SelectedStringView(string: selected)
                } else {
                    Text("No Selection").foregroundStyle(.secondary)
                }
            }
                .frame(maxWidth:.infinity, maxHeight: .infinity)
                .layoutPriority(1)
        }
    }
}


//MARK: - String Views
fileprivate struct SelectedStringView : View {
    let string: FilerSearchString
    @Query(sort: \FilerFolder.name)   var folders: [FilerFolder]
    @State private var selectedFolder :FilerFolder?

    var filteredFolders : [FilerFolder] {
        folders.filter { folder in
            folder.searchStrings?.contains(string) ?? false
        }
    }
    var cases : [FilerCase] {
        var casesFound : [FilerCase] = []
        for filteredFolder in filteredFolders {
            if let aCase = filteredFolder.aCase, !casesFound.contains(aCase) {
                casesFound.append(aCase)
            }
        }
        return casesFound.sorted(by: {$0.name < $1.name})
    }
    var body : some View {
        List(selection:$selectedFolder) {
            if folders.isEmpty {
                Text("No folders found")
            } else {
                ForEach(cases) { aCase in
                    Section(aCase.name) {
                        ForEach(filteredFolders.filter({$0.aCase == aCase }), id:\.self) { folder in
                            SD_Filer_FolderRow(folder: folder)
                        }
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
            .alternatingRowBackgrounds()
            .inspector(isPresented: .constant(selectedFolder != nil)) {
                if let selectedFolder {
                    SelectedFolderView(folder: selectedFolder)
                        .inspectorColumnWidth(300)
                }
            }
        
    }
}

#Preview {
    SD_Filer_SearchStringsView()
        .modelContainer(BOF_SwiftData.shared.container)

}
