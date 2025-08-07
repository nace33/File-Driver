//
//  SD_FilerCaseView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/29/25.
//

import SwiftUI
import SwiftData


//MARK: - All Cases View
struct SD_Filer_CasesView: View {
    @State private var selected: FilerCase?
    @Query(sort: \FilerCase.name)   var cases: [FilerCase]
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
        HSplitView {
            List(selection: $selected) {
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
                .frame(minWidth:150, maxWidth:250)

            VStack {
                if let selected {
                    SelectedCaseView(aCase: selected)
                } else {
                    Text("No Selection").foregroundStyle(.secondary)
                }
            }
                .frame(maxWidth:.infinity, maxHeight: .infinity)
                .layoutPriority(1)
        }
    }

}


//MARK: - Selected Case View
fileprivate struct SelectedCaseView : View {
    let aCase : FilerCase
    @Query private var folders: [FilerFolder] // Declares the Query
    @State private var selectedFolder :FilerFolder?

     init(aCase: FilerCase) {
         self.aCase = aCase // Assign the input article
         let spreadsheetID = aCase.spreadsheetID
         _folders = Query(filter: #Predicate { $0.aCase?.spreadsheetID == spreadsheetID   })
     }
    
    @Environment(\.modelContext) var context

    var body: some View {
        List(selection:$selectedFolder) {
            if folders.isEmpty {
                Text("No folders found")
            } else {
                Section("Folders") {
                    ForEach(aCase.folders ?? [], id:\.self) { folder in
                        SD_Filer_FolderRow(folder: folder)
                    }
                }
                    .listRowSeparator(.hidden)
            }
        }
            .alternatingRowBackgrounds()
            .task(id:aCase.folders) {
                if let selectedFolder, let folders = aCase.folders, !folders.contains(selectedFolder) {
                    self.selectedFolder = nil
                }
            }
            .inspector(isPresented: .constant(selectedFolder != nil)) {
                if let selectedFolder {
                    SelectedFolderView(folder: selectedFolder)
                        .inspectorColumnWidth(300)
                }
            }
        
    }
}


//MARK: - Selected Folder
struct SelectedFolderView : View {
    let folder : FilerFolder
    
    var body: some View {
        List {
            ForEach(FilerSearchString.Category.allCases, id:\.self) { category in
                if let items = folder.searchStrings?.filter({$0.category == category }), items.count > 0 {
                    Section(category.title) {
                        ForEach(items) { row in
                            SD_Filer_SearchStringRow(searchString: row)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
    }
}


//MARK: - Preview
#Preview {
    SD_Filer_CasesView()
        .modelContainer(BOF_SwiftData.shared.container)
}
