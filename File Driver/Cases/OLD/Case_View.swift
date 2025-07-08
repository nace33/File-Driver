//
//  Case_View.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/16/25.
//

import Foundation
import SwiftUI

struct Case_View: View {
    let aCase : Case_OLD
    @State private var isLoading = false
    @State private var sheet : Case_OLD.Sheet = .folders
    
    
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
                ForEach(Case_OLD.Sheet.allCases, id:\.self) { Text($0.title)}
            }.pickerStyle(.segmented)
        }
    }
}





import GoogleAPIClientForREST_Drive
struct Case_Folders : View {
    let aCase : Case_OLD
    @State private var showNewFolderSheet = false
    @State private var selectedFolder : Case_OLD.Folder?
    @State private var editFolder : Case_OLD.Folder?
    var body: some View {
        List(selection:$selectedFolder) {
            Button("New") { showNewFolderSheet.toggle() }
                .sheet(isPresented: $showNewFolderSheet) { Case_OLD.FolderNew(aCase: aCase) { selectedFolder = $0 }}
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
            Case_OLD.Folder.Edit(editFolder, in:aCase)
        }
        .task(id:aCase.id) { await loadFolders() }
        
    }
    func loadFolders() async {
        do {
            let folders = try await Drive.shared.getContents(driveID: aCase.driveID, onlyFolders: true)
            print("Folders: \(folders.count)")
            aCase.folders = folders.compactMap { .init($0) }
                                   .sorted { $0.name.ciCompare($1.name) }
            
        } catch {
            print(#function + " \(error.localizedDescription)")
        }
    }
    func delete(_ folder:Case_OLD.Folder) {
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
    let aCase : Case_OLD
    var body: some View {
        Text("Tags")
    }
}

struct Case_Filings : View {
    let aCase : Case_OLD
    var body: some View {
        Text("Files")
    }
}

