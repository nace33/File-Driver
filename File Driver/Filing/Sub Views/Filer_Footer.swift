//
//  Filer.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/21/25.
//

import SwiftUI


struct Filer_Footer : View {
    @Environment(Filer_Delegate.self) var delegate
    @AppStorage(BOF_Settings.Key.filingDrive.rawValue)       var driveID : String = ""
    @State private var showGetDriveSheet = false
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("Filer_Footer-SavedFolders") fileprivate var savedFolders : [SavedFolder] = []
    
    var body : some View {
        HStack {
            if !delegate.items.isEmpty, delegate.actions.contains(.saveTo) {
                saveToMenu
                    .fixedSize()
                    .disabled(delegate.loader.isLoading)
            }

            Spacer()
            if delegate.actions.contains(.cancel) {
                Button("Cancel")      { cancelButtonPressed()    }
            }
            
            if delegate.actions.contains(.reset) {
                Button("Reset") { resetButtonPressed() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                    .disabled(delegate.loader.isLoading || !delegate.canReset)
            }
            
            if delegate.canShowForm {
                Button("Add To \(delegate.mode == .cases ? "Case" : "Folder")")        { addToButtonPressed()     }
                    .frame(width: 100)
                    .buttonStyle(.borderedProminent)
                    .disabled(!delegate.canFileItems || delegate.loader.isLoading)
            } else {
                Button(selectTitle) { selectButtonClicked() } 
                    .frame(width: 100)
                    .buttonStyle(.borderedProminent)
                    .disabled(!delegate.canSelectItem || delegate.loader.isLoading)

            }
        }
            .frame(minHeight:38)
            .padding(.horizontal)
            .lineLimit(1)
            .sheet(isPresented: $showGetDriveSheet) {
                DriveSelector("Select Filing Drive", canLoadFolders: false) { file in
                    driveID = file.driveId ?? ""
                    showGetDriveSheet = false
                }
                    .frame(minHeight: 400)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showGetDriveSheet = false }
                        }
                    }
            }
    }
    
    //Actions
    ///Select
    var selectTitle : String {
        switch delegate.mode {
        case .cases:
            if delegate.selectedCase == nil {
                "Select Case"
            } else {
                "Select Folder"
            }
        case .folders:
            if delegate.stack.isEmpty {
                "Select Drive"
            } else {
                "Select Folder"
            }
        }
    }
    func selectButtonClicked() {
        switch delegate.mode {
        case .cases:
            if delegate.selectedCase == nil {
                if let selCase = delegate.caseListSelection {
                    delegate.select(selCase)
                }
            } else if let selFolder = delegate.folderListSelection {
                ///Can be used with .transition animations
//                withAnimation {
                    delegate.select(selFolder)
//                }
            }
        case .folders:
            if let selFolder = delegate.folderListSelection {
//                withAnimation {
                    delegate.select(selFolder)
//                }
           }
        }
    }
    
    ///Save To
    func saveToButtonPressed(_ saveToID:String) {
        Task {
            do {
                try await delegate.saveTo(saveToID)
                if delegate.actions.contains(.cancel) {
                    dismiss()
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    ///Cancel
    func cancelButtonPressed() {
        delegate.trashLocalFiles()
        dismiss()
    }
    
    ///Reset
    func resetButtonPressed() {
        delegate.resetCaseVariables()
        delegate.resetFolderVariables()
        Task { await delegate.load() }
    }
    
    //Add To
    func addToButtonPressed() {
        guard delegate.canFileItems else { return }
        Task {
            do {
                switch delegate.mode {
                case .cases:
                    try await delegate.saveToSelectedCase()
                case .folders:
                    if let selFolder = delegate.selectedFolder {
                        try await delegate.saveTo(selFolder.id)
                    }
                }
                addToRecentFolders()
                if delegate.actions.contains(.cancel) {
                    dismiss()
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    
    //View Builder
    @ViewBuilder var saveToMenu : some View {
        Menu("Quick Save") {
            if driveID.isEmpty {
                Button("Set Filing Drive") { showGetDriveSheet = true }
            } else {
                Button("Filing") { saveToButtonPressed(driveID)}
                    .modifierKeyAlternate(.command) {
                        Button("Set Filing Drive") { showGetDriveSheet = true }
                    }
            }
            let recentFolders = savedFolders.filter { $0.isFavorite == false }
            if recentFolders.count > 0 {
                Menu("Recents") {
                    ForEach(recentFolders.sorted(by: {$0.date < $1.date})) { recent in
                        Button(recent.displayTitle) { saveToButtonPressed(recent.id)  }
                    }
                    if recentFolders.count > 0 {
                        Divider()
                        Button("Clear Recent Folders") { savedFolders.removeAll(where: {$0.isFavorite == false }) }
                    }
                }
            }
            let favoriteFolders = savedFolders.filter({ $0.isFavorite })
            if favoriteFolders.count > 0 || (delegate.mode == .folders && delegate.folderListSelection != nil && delegate.folderListSelection?.id != driveID) {
                Menu("Favorites") {
                    ForEach(favoriteFolders.sorted(by: {$0.date < $1.date})) { favorite in
                        Button(favorite.displayTitle) { saveToButtonPressed(favorite.id)  }
                            .modifierKeyAlternate(.command) {
                                Button("Remove \(favorite.displayTitle)") {
                                    if let index = savedFolders.firstIndex(where: {$0.id == favorite.id && $0.isFavorite}) {
                                        savedFolders.remove(at: index)
                                    }
                                }
                            }
                    }
                    if delegate.mode == .folders,
                        let selectedFolder = delegate.folderListSelection,
                        selectedFolder.id != driveID,
                        recentFolders.first(where:({$0.isFavorite && $0.id == selectedFolder.id})) == nil {
                        
                        if favoriteFolders.count > 0 {
                            Divider()
                        }
                        Button("Add \(selectedFolder.title)") { addToFavoriteFolders()}
                    }
                    if favoriteFolders.count > 0 {
                        Divider()
                        Button("Clear Favorite Folders") { savedFolders.removeAll(where: {$0.isFavorite })}
                    }
                }
            }
        }
    }
    
    
    //Favorites
    func addToRecentFolders()   {
        if delegate.mode == .folders,
            let selectedFolder = delegate.selectedFolder,
            selectedFolder.id != driveID {
            
            if let index = savedFolders.firstIndex(where:{$0.id == selectedFolder.id && !$0.isFavorite}) {
                savedFolders[index].date = Date()
            } else {
                let recents = savedFolders.filter({!$0.isFavorite})
                if recents.count > 5, let last = recents.last, let index = savedFolders.firstIndex(where: {$0.id == last.id && !$0.isFavorite}) {
                    savedFolders.remove(at: index)
                }
                let path = delegate.stack.map(\.title)
                savedFolders.append(SavedFolder(id: selectedFolder.id, title: selectedFolder.title, path:path, date: Date(), isFavorite:false))
            }
        }
    }
    func addToFavoriteFolders() {
        guard let selectedFolder = delegate.folderListSelection, selectedFolder.id != driveID else { return  }
        let path = delegate.stack.map(\.title)
        savedFolders.append(SavedFolder(id: selectedFolder.id, title: selectedFolder.title, path: path, date: Date(), isFavorite:true))
    }
}



fileprivate struct SavedFolder : Identifiable, Codable {
    var id         : String
    var title      : String
    var path       : [String]
    var date       : Date
    var isFavorite : Bool = false
    var displayTitle : String {
        if path.count == 1 {
            title
        }
        else if path.count > 3, let last = path.last {
            path[0] + "/" + path[1] + "/.../" + last
        } else {
            path.joined(separator: "/")
        }
    }
}
