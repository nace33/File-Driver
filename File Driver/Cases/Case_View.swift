//
//  Case_View.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/16/25.
//

import Foundation
import SwiftUI

struct Case_View: View {
    let aCase : Case
    @State private var isLoading = false
    @State private var sheet : Case.Sheet = .folders
    
    
    var body: some View {
        VStack {
            if isLoading {ProgressView() }
            else {
                switch sheet {
                case .folders:
                    Text("Drive Navigator Here")
                
                case .contacts:
                    Case_Contacts_List(aCase: aCase)
                case .tags:
                    Case_Tags(aCase: aCase)
                case .filings:
                    Case_Filings(aCase: aCase)
                }
            }
        }.task(id:aCase.id) {
            isLoading = true
            await aCase.load([.contacts])
            isLoading = false
        }
        .toolbar {
            Picker("Sheet", selection: $sheet) {
                ForEach(Case.Sheet.allCases, id:\.self) { Text($0.title)}
            }.pickerStyle(.segmented)
        }
    }
}





import GoogleAPIClientForREST_Drive
struct Case_Folders : View {
    let aCase : Case
    @State private var showNewFolderSheet = false
    @State private var selectedFolder : Case.Folder?
    @State private var editFolder : Case.Folder?
    var body: some View {
        List(selection:$selectedFolder) {
            Button("New") { showNewFolderSheet.toggle() }
                .sheet(isPresented: $showNewFolderSheet) { Case.FolderNew(aCase: aCase) { selectedFolder = $0 }}
            aCase.folderMenu { folder in
                selectedFolder = folder
            }.fixedSize()
            if aCase.folders.isEmpty { Text("No Folders").foregroundStyle(.secondary) }
            ForEach(aCase.rootFolders, id:\.self) { folder in
                Text(folder.name /*+ " (" + folder.id + ")" + " (" + folder.parentID + ")" */)
                    .contextMenu {
                        Button("Edit") {editFolder = folder }
                        if aCase.canDelete(folder: folder) {
                            Button("Delete") { delete(folder)}
                        }
                    }
            }
        }
        .sheet(item: $editFolder) { editFolder in
            Case.Folder.Edit(editFolder, in:aCase)
        }
        .task(id:aCase.id) { await loadFolders() }
        
    }
    func loadFolders() async {
        do {
            let folders = try await Google_Drive.shared.getContents(driveID: aCase.driveID, onlyFolders: true)
            print("Folders: \(folders.count)")
            aCase.folders = folders.compactMap { .init($0) }
                                   .sorted { $0.name.ciCompare($1.name) }
            
        } catch {
            print(#function + " \(error.localizedDescription)")
        }
    }
    func delete(_ folder:Case.Folder) {
        Task {
            do {
                try await aCase.delete(folder: folder)
            }
            catch {
                print("Error deleting folder: \(error)")
            }
        }
    }
}


struct Case_Tags : View {
    let aCase : Case
    var body: some View {
        Text("Tags")
    }
}

struct Case_Filings : View {
    let aCase : Case
    var body: some View {
        Text("Files")
    }
}

