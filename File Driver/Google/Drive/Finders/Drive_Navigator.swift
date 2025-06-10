//
//  Drive_Navigator.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/22/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce
import UniformTypeIdentifiers

struct Drive_Navigator: View {
    var rootID   : String
    var rootname : String
    var onlyFolders = true
    var useSystemImage : Bool = true
    var headerElements : [HeaderElement] = HeaderElement.defaults
    var abilities      : [Ability] = Ability.defaults
    var action : (Action, GTLRDrive_File?) -> Void
    
    //Stack State
    @State private var isLoading = false
    @State private var stack : [GTLRDrive_File] = []
    @State private var files : [GTLRDrive_File] = []
    @State private var selection : GTLRDrive_File?
    @State private var error : Error? = nil

    //Abilitiy state
    @State private var showNewFolderSheet = false
    @State private var renameItem : GTLRDrive_File?
    @State private var deleteItem : GTLRDrive_File?
    @State private var shareItem  : GTLRDrive_File?
    @State private var downloadData  : Data = Data()
    @State private var downloadFilename : String? = nil
    @State private var showDownloadExport = false
    @State private var downloadProgress : Float = 0
    @State private var isDownloading     = false
    
    var body: some View {
        VStack(alignment:.leading, spacing:0) {
            header
            
            List(selection: $selection) {
                if !isLoading, files.isEmpty { Text("No Files").foregroundStyle(.secondary)}
                else if let error { errorView(error)  }
                
                ForEach(files, id:\.self) { file in
                    row(file)
                }
            }
                .onChange(of: selection, { oldValue, newValue in
                    action(.single, newValue ?? stack.last)
                })
                .contextMenu(forSelectionType: GTLRDrive_File.self, menu: { items in
                    rightClickMenu(items.first)
                }, primaryAction: { items in
                    guard let file = items.first else { return }
                     if file.isFolder {
                        push(file)
                    } else {
                        action(.double, file)
                    }
                })
                .sheet(isPresented: $showNewFolderSheet) { newFolderView }
                .sheet(item: $renameItem) { renameView($0) }
                .sheet(item: $deleteItem) { deleteView($0) }
                .sheet(item: $shareItem ) { shareView($0 ) }
                .fileExporter(isPresented: $showDownloadExport,
                              item: downloadData,
                              defaultFilename:downloadFilename) { processExportResult($0)}
        }
            .disabled(isLoading)
            .opacity(isLoading ? 0.5 : 1.0)
            .task(id:stack) {
                files = await loadFiles(id: stack.last?.id)
                sortFiles()
            }
        //Note that the inspect can cause crash
        //Cannot register more than one NSTrackingSeparatorToolbarItem that tracks the same divider
//        .inspector(isPresented: Binding(get: {showInspector}, set: {_ in})) {
//            if showInspector, let selection  {
//                Drive_Navigator_Inspector(file: selection)
//                    .inspectorColumnWidth(min: 400, ideal: 500)
//            }
//        }
    }
}


//MARK: View Builders
extension Drive_Navigator {
    //View Builders
    //Error
    @ViewBuilder func errorView(_ error:Error) -> some View {
        Spacer()
        Text("Error: \(error.localizedDescription)")
        Button("Reload") { self.error = nil; pop() }
        Spacer()
    }
    
    //Header
    @ViewBuilder var header : some View {
        if !headerElements.isEmpty  {
            HStack(spacing:0) {
                if headerElements.contains(.backButton) {
                    Button {
                        action(.rootBack, nil)
                    } label: { Image(systemName: "chevron.left")}
                        .buttonStyle(.plain)
                        .padding(8)
                }
                
                if headerElements.contains(.pathBar) {
                    pathBar
                }
                
                if headerElements.contains(.picker) {
                    picker
                }
                Spacer()

                if headerElements.contains(.deleteButton) {
                    Button { deleteItem = headerDeleteItem } label: {  Image(systemName: "trash")   }
                        .disabled(headerDeleteItem == nil)
                        .buttonStyle(.plain)
                        .padding(.trailing)

                }
                if headerElements.contains(.downloadButton) {
                    Button { Task { await download(headerDownloadItem!)} } label: {
                        if !isDownloading  {
                            Image(systemName: "arrow.down.circle")
                        }
                        else if downloadProgress == 0 {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.5)
                                .frame(width:15, height:15)
                        }
                        else {
                            ProgressView(value: downloadProgress)
                                .progressViewStyle(.circular)
                                .scaleEffect(0.5)
                                .frame(width:15, height:15)
                        }
                    }
                        .buttonStyle(.plain)
                        .padding(.trailing)
                        .disabled(headerDownloadItem == nil || isDownloading)
                }
                if headerElements.contains(.newButton), abilities.contains(.newFolder) {
                    Button { showNewFolderSheet.toggle()} label: {Image(systemName: "folder.badge.plus")}
                        .buttonStyle(.plain)
                        .padding(.trailing)
                }
                if headerElements.contains(.shareButton) {
                    Button { shareItem = headerShareItem } label: {  Image(systemName: "person.2.fill")   }
                        .buttonStyle(.plain)
                        .padding(.trailing)
                }
            }
            Divider()
        }
    }
    @ViewBuilder var picker  : some View {
        if stack.count > 0 {
            Picker("", selection:Binding(get: {stack.last}, set: { newValue in
                if stack.count > 0 {
                    if newValue != stack.last {
                        goBack()
                    }
                }
                else { pop(newValue)}
            })) {
                ForEach(stack.reversed()) { group in
                    Text(group.title)
                        .tag(group as GTLRDrive_File?)
                }
                Text(rootname)
                    .tag(nil as GTLRDrive_File?)
                
            }
            .fixedSize()
            .labelsHidden()
            .pickerStyle(.menu)
            .buttonStyle(.borderless)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        } else {
            Text(rootname)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
    }
    @ViewBuilder var pathBar : some View {
        HStack {
            if stack.count > 0 {
                Button(rootname) { stack.removeAll(); action(.pop, nil) }
                    .dropDestination(for: GTLRDrive_File.ID.self) { items, location in
                        Task { try? await move(id: items.first, newParentID:rootID) }
                        return canMove(id: items.first, newParentID:rootID)
                    }
            } else {
                Text(rootname).foregroundStyle(.secondary)
                    .dropDestination(for: GTLRDrive_File.ID.self) { items, location in
                        Task { try? await move(id: items.first, newParentID:rootID) }
                        return canMove(id: items.first, newParentID:rootID)
                    }
            }
            ForEach(stack, id:\.self) { folder in
                if folder == stack.last {
                    Label(folder.title, systemImage: "chevron.right")
                        .foregroundStyle(.secondary)
                        .dropDestination(for: GTLRDrive_File.ID.self) { items, location in
                            Task { try? await move(id: items.first, newParentID:folder.id) }
                            return canMove(id: items.first, newParentID:folder.id)
                        }
                } else {
                    Button(folder.title, systemImage: "chevron.right") { pop(folder)}
                        .dropDestination(for: GTLRDrive_File.ID.self) { items, location in
                            Task { try? await move(id: items.first, newParentID:folder.id) }
                            return canMove(id: items.first, newParentID:folder.id)
                        }
                }
            }
        }
            .lineLimit(1)
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
    }

    //Row
    @ViewBuilder func row(_ file:GTLRDrive_File) -> some View {
        if file.isFolder, abilities.contains(.move) {
            rowLabel(file)
                .dropDestination(for: GTLRDrive_File.ID.self) { items, location in
                    Task { try? await move(id: items.first, newParentID: file.id) }
                    return canMove(id: items.first, newParentID: file.id)
                }
                .draggable(file.id)
        }
        else if abilities.contains(.move) {
            rowLabel(file)
                .draggable(file.id)
        }
        else {
            rowLabel(file)
        }
    }
    @ViewBuilder func rowLabel(_ file:GTLRDrive_File) -> some View {
        if useSystemImage  {
            Label(file.title, systemImage: file.imageString)
        } else {
            Label {
                Text(file.title)
            } icon: {
                file.icon
            }
        }
    }
    //Menus
    @ViewBuilder func rightClickMenu(_ file:GTLRDrive_File?) -> some View {
        if let file {
            if abilities.contains(.rename){
                Button("Rename") { renameItem = file}
            }
            if abilities.contains(.move) {
                Menu("Move To") {
                    if stack.count > 0 {
                        Button(rootname) {Task { try? await move(id: file.id, newParentID:rootID) }  }
                        if stack.count > 1 {
                            Divider()
                            ForEach(stack, id:\.self) { parent in
                                Button(parent.title) { Task { try? await move(id: file.id, newParentID: parent.id) }  }
                            }
                        }
                        Divider()
                    }
                
                    let siblings = files.filter { $0.isFolder && $0 != file}
                    ForEach(siblings, id:\.self) { sibling in
                        Button(sibling.title) { Task { try? await move(id: file.id, newParentID: sibling.id) }   }
                    }
                }
            }
            if abilities.contains(.download), !file.isFolder {
                Button("Download") { Task { await download(file)} }
            }
            if abilities.contains(.share) {
                Button("Share") {  shareItem = file }
            }
            if abilities.contains(.delete), !file.isFolder{
                if abilities.count > 1 { Divider() }
                Button("Delete") { deleteItem = file}
            }
        } else {
            if abilities.contains(.newFolder) {
                Button("New Folder") {showNewFolderSheet.toggle() }
            }
            if abilities.contains(.share) {
                Button("Share") {
                    let file = GTLRDrive_File()
                    file.identifier = rootID
                    file.name = rootname
                    shareItem = file
                }
            }
        }
    }
}


//MARK: Stack
extension Drive_Navigator {
    func goBack() {
        selection = nil
        if stack.count > 0 {
            stack.removeLast()
            action(.pop, stack.last)
        } else {
            action(.rootBack, nil)
        }
    }
    func pop(_ item:GTLRDrive_File? = nil) {
        selection = nil
        if let item, let index = stack.firstIndex(where: {$0.id == item.id}) {
            stack.removeSubrange((index + 1)..<stack.count)
        } else {
            stack.removeAll()
        }
        action( .pop, stack.last)
    }
    func push(_ item:GTLRDrive_File) {
        selection = nil
        if !stack.map(\.id).contains(item.id) {
            stack.append(item)
            action(.push, item)
        }
    }
    
    //Load
    func loadFiles(id:String?) async -> [GTLRDrive_File] {
        isLoading = true
        files = []
        var f = [GTLRDrive_File]()
        do {
            if let id {
                f = try await Google_Drive.shared.getContents(of: id, onlyFolders: onlyFolders)
            }
            else if rootID.isEmpty {
                f = try await Google_Drive.shared.sharedDrivesAsFolders()
            }
            else {
                f = try await Google_Drive.shared.getContents(of: rootID, onlyFolders: onlyFolders)
            }
            
        
            
            isLoading = false
            
            return f
        } catch {
            isLoading = false
            self.error = error
            return []
        }
    }
    func sortFiles() {
        files.sort { $0.title.ciCompare($1.title)}
    }
}

//MARK: Abilities
extension Drive_Navigator {
    ///New Folder
    @ViewBuilder var newFolderView : some View {
        TextSheet(title: "New Folder", prompt: "Create") { name in
            do {
                try await createNewFolder(name, parentID: stack.last?.id ?? rootID)
                return nil
            } catch {
                return error
            }
        }
    }
    func createNewFolder(_ name:String, parentID:String) async throws  {
        do {
            let newFolder = try await Google_Drive.shared.create(folder: name, in:stack.last?.id ?? rootID)
            files.append(newFolder)
            sortFiles()
            selection = newFolder
        } catch {
            throw error
        }
    }
   
    ///Rename
    @ViewBuilder func renameView(_ item:GTLRDrive_File) -> some View {
        TextSheet(title: "Rename", prompt: "Save", string:item.title) { newName in
            do { try await rename(newName, id:item.id); return nil}
            catch { return error }
        }
    }
    func rename(_ name:String, id:String) async throws {
        do {
            let renamedFile = try await Google_Drive.shared.rename(id: id, newName: name)
            if let index = files.firstIndex(where: {$0.id == id}) {
                files.remove(at: index)
                files.append(renamedFile)
                sortFiles()
                //                selection = renamedFile
            }
        } catch {
            throw error
        }
    }
    
    ///Move
    func canMove(id:String?, newParentID:String) -> Bool {
        guard let id else { return false }
        guard id != newParentID else { return false }
        guard let index = files.firstIndex(where: {$0.id == id }) else { return false }
        guard let currentParentID = files[index].parents?.first else { return false }
        guard currentParentID != newParentID else { return false }
        return true
    }
    func move(id:String?, newParentID:String) async throws  {
        guard let id else { return }
        guard let index = files.firstIndex(where: {$0.id == id }) else { return }
        guard let currentParentID = files[index].parents?.first else { return }
        guard canMove(id: id, newParentID: newParentID) else { return }
        do {
            isLoading = true
            _ = try await Google_Drive.shared.move(fileID: id, from:currentParentID, to: newParentID)
            if selection == files[index] {
                selection = nil
            }
            files.remove(at: index)
            isLoading = false

        } catch {
            isLoading = false
            throw error
        }
    }
    
    ///Delete
    @ViewBuilder func deleteView(_ item:GTLRDrive_File) -> some View {
        ConfirmationSheet(title: "Move '\(item.title)' to Trash",
                          message: "Google Drive will permanently delete this \(item.isFolder ? "folder": "file") in 30 days.  Prior to deletion, '\(item.title)', can be restored from Drive's Trash folder.",
                          prompt: "Move to trash") {
            do {
                try await delete(id:item.id)
            } catch { throw error }
        }
    }
    func delete(id:String) async throws {
        guard let index = files.firstIndex(where: {$0.id == id }) else { return }
        do {
            guard try await Google_Drive.shared.delete(ids: [id]) else { return }
            files.remove(at: index)
        } catch {
            throw error
        }
    }
    
    ///Share
    var headerShareItem : GTLRDrive_File {
        if let selection { return selection }
        else if let last = stack.last { return last }
        else {
            let root = GTLRDrive_File()
            root.identifier = rootID
            root.name = rootname
            return root
        }
    }
    var headerDeleteItem : GTLRDrive_File? {
        let item = selection
        return item?.id == rootID ? nil : item
    }
    var headerDownloadItem : GTLRDrive_File? {
        guard let item = selection else { return nil }
        return item.isFolder ? nil : item
    }
    @ViewBuilder func shareView(_ item:GTLRDrive_File) -> some View {
        Google_Drive_Permissions(file: item)
    }
    
    ///Download
    func download(_ file:GTLRDrive_File) async {
        do {
            isDownloading = true
//            let fileURL =  file.downloadURL(directory:URL.downloadsDirectory)
//            let data = try await Google_Drive.shared.download(file, to: fileURL, progress: { progress in
//                if downloadProgress != progress {
//                    downloadProgress = progress
//                }
//            })
            let download = try await Google_Drive.shared.download(file) { progress in
                if downloadProgress != progress {
                    downloadProgress = progress
                }
            }
            downloadData = download
            downloadFilename = file.downloadFilename
            showDownloadExport = true
            isDownloading = false
        } catch {
            isDownloading = false
            downloadData = Data()
            downloadFilename = nil
            self.error = error
        }
    }
    func processExportResult(_ result:Result<URL, Error>) {
        switch result {
        case .success(let urls):
            print("Exported: \(urls)")
            break
        case .failure( let error):
            print("Export Failed: \(error.localizedDescription)")
            self.error = error
        }
        downloadData = Data()
        downloadFilename = nil
    }
    
    ///Inspector
    var showInspector : Bool {
        guard abilities.contains(.inspector) else { return false }
        guard let selection else { return false }
        return !selection.isFolder
    }
}


//MARK: Enums
extension Drive_Navigator {
    enum Action { case single, double, pop, push, rootBack }
    enum HeaderElement {
        case pathBar, picker, shareButton, deleteButton, newButton, backButton, downloadButton
        
        static var defaults : [HeaderElement] { [.pathBar] }
        static var deluxe : [HeaderElement] { [.backButton, .pathBar, .newButton, .shareButton, .deleteButton, .downloadButton] }
    }
    enum Ability : String, CaseIterable {
        case rename, newFolder, move, delete, share, download, inspector
        static var defaults : [Ability] { [/* Empty */]}
        static var deluxe : [Ability] { [.newFolder, .rename, .move, .delete, .share, .download, .inspector]}
    }
}

#Preview {
    let id = "1v2ONNBqcVsZQkdWA95c751fw65L5Ogt3"
    let name = "File Driver"
    Drive_Navigator(rootID: id, rootname: name) { action, file in
        
    }
        .environment(Google.shared)

}
