//
//  Google.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive



@Observable
public
class Google_DriveDelegate  {
    init(actions: [Google_DriveDelegate.Action] = [.refresh], labelIDs:[String]? = nil, mimeTypes:[GTLRDrive_File.MimeType]? = nil) {
        self.actions = actions
        self.labelIDs = labelIDs
        self.mimeTypes = mimeTypes
    }
    static func selecter(labelIDs:[String]? = nil, mimeTypes:[GTLRDrive_File.MimeType]? = nil) -> Google_DriveDelegate {
        Google_DriveDelegate(actions: [.select], labelIDs: labelIDs, mimeTypes: mimeTypes)
    }
    static func deluxe(labelIDs:[String]? = nil, mimeTypes:[GTLRDrive_File.MimeType]? = nil)   -> Google_DriveDelegate {
        Google_DriveDelegate(actions:Google_DriveDelegate.Action.allCases, labelIDs: labelIDs, mimeTypes: mimeTypes)
    }
    
    var doubleClicked : GTLRDrive_File?  = nil
    var selected      : GTLRDrive_File?  = nil
    private(set)var files  : [GTLRDrive_File] = []
    private(set)var stack  : [GTLRDrive_File] = []
    
    //Filter
    var filter      = ""
    
    //Loading
    typealias customLoader = () async throws->[GTLRDrive_File]
    private(set)var load        : customLoader?
    private(set)var isLoading   = true //only set in loadStack()
    //Useful when Google_DriveView, custom list is used to syncrhomize sequences of loading for views.  Otherwise, a list can load, then a view displays before it is ready
    private(set)var stackWillReloadSoon : Bool   = false //Set to signal reload is about to occur.  Set to false in load after isLoading is set to true and reloading begins
    var error       : Error?
    var labelIDs    : [String]?
    var mimeTypes   : [GTLRDrive_File.MimeType]?
    
    
    
    //Actions
    var actions          : [Google_DriveDelegate.Action]
    var renameItem       : GTLRDrive_File?  = nil
    var selectItem       : GTLRDrive_File?  = nil
    var shareItem        : GTLRDrive_File?  = nil
    var deleteItem       : GTLRDrive_File?  = nil
    var uploadToFolder   : GTLRDrive_File?  = nil
    var showUploadSheet  = false

    //Move
    var moveItemIDs      : [String]  = []
    
    //Downloading
    var downloadItems    : [Google_DriveDelegate.DownloadItem]  = []
    var downloadData     : Data?   = nil
    var downloadFilename : String? = nil
    var showDownloadExport         = false
    var showNewFolderSheet         = false

    //Uploading
    var uploadItems      : [Google_DriveDelegate.UploadItem]  = []
    
    
    public enum Action : String, CaseIterable {
        case select, rename, newFolder, move, share, upload, download, delete, refresh, filter
        static var toolbarActions : [Action] { [.select, .rename, .newFolder, .share, .upload, .download, .delete, .refresh, .filter]}
        var title       : String { rawValue.camelCaseToWords() }
        var iconName    : String {
            switch self {
            case .filter :
                "line.3.horizontal.decrease"
            case .refresh:
                "arrow.clockwise"
            case .rename:
                "pencil"
            case .newFolder:
                "folder.badge.plus"
            case .move:
                "inset.filled.rectangle.and.cursorarrow"
            case .delete:
                "trash"
            case .share:
                "person.2.fill"
            case .upload:
                "arrow.up.circle"
            case .download:
                "arrow.down.circle"
            case .select:
                "filemenu.and.selection"
            }
        }
    }
    
}
//MARK: - Load Stack
extension Google_DriveDelegate {
    var filteredFiles: [GTLRDrive_File] {
        guard  actions.contains(.filter), !filter.isEmpty else { return files }
        return files.filter { file in
            file.title.ciContain(filter)
        }
    }
    var filteredBoundFiles: Binding<[GTLRDrive_File]> {
        guard  actions.contains(.filter), !filter.isEmpty else { return Bindable(self).files }
        return Binding {
            self.files.filter { file in
                file.title.ciContain(self.filter)
            }
        } set: { newValue in
            self.files = newValue
        }
    }
}

//MARK: - Load Stack
extension Google_DriveDelegate {
    func refresh() {
        Task {
            await loadStack()
        }
    }
    func addToStack(_ file:GTLRDrive_File) {
        stackWillReloadSoon = true
        stack.append(file)
    }
    func removeAllFromStack() {
        stackWillReloadSoon = true
        stack.removeAll()
    }
    func removeRangeFromStack(_ range:Range<Int>) {
        stackWillReloadSoon = true
        stack.removeSubrange(range)
    }
    func loadStack(_ customLoad:customLoader? = nil) async {
        do {
            self.error = nil
            isLoading = true
            files = []
            filter = ""
            selectItem = nil
            doubleClicked = nil
            stackWillReloadSoon = false
            if let customLoad {//currently only a customLoad is set in Google_DriveView.task(id:...)
                load = customLoad //save reference so other functions that call this (i.e. refresh) call the custom load
                files = try await customLoad()
                selected = stack.last
            }
            else if let load {//this load call is set above, originally passed in from Google_DriveView.task(id:...)
                files = try await load()
                selected = stack.last
            }
            else if let last = stack.last, last.isFolder {
                files = try await Google_Drive.shared.getContents(of: last.id, labelIDs: labelIDs, onlyFolders: onlyFolders)
                                                     .filter { validatedMimeTypes?.contains($0.mime) ?? true }
                selected = last
            } else {
                files = try await Google_Drive.shared.sharedDrivesAsFolders()
                selected = nil
            }
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
        }
    }
}


//MARK: - Computed Properties
extension Google_DriveDelegate {
    private var validatedMimeTypes : [GTLRDrive_File.MimeType]? {
        guard var mimeTypes = mimeTypes else { return nil }
        if !mimeTypes.contains(.folder) {
            mimeTypes.append(.folder)
        }
        return mimeTypes
    }
    private var onlyFolders : Bool {
        guard let mimeTypes = mimeTypes,
                mimeTypes.count == 1,
                mimeTypes.first! == .folder else { return false }
        return true
    }
    func canPerform(_ action:Action, on file:GTLRDrive_File?) -> Bool {
        switch action {
        case .refresh:
            !isLoading
        case .select:
            canSelect(file:file)
        case .rename:
            canRename(file:file)
        case .newFolder:
            canCreateNewFolder
        case .share:
            canShare(file:file)
        case .upload:
            canUpload(to: file)
        case .download:
            canDownload(file:file)
        case .delete:
            canDelete(file: file)
        case .move, .filter:
            false
        }
    }
}


//MARK: - Sort
extension Google_DriveDelegate {
    private func sortFiles() {
        files.sort { $0.title.ciCompare($1.title)}
    }
}


//MARK: - Select
extension Google_DriveDelegate {
    ///True when:
    /// 1) One of the following is true
    ///     A) passedIn file != nil (i.e. there is an item selected in the list or the menuItem that passed to this function is set);
    ///     B) stack.last is a folder
    /// 2) And, one of the following is true
    ///     A) mimeTypes is nil
    ///     B) mimeTypes.contains the mimeType of the item in 1 above
    ///
    func canSelect(file:GTLRDrive_File?) -> Bool {
        guard let item = file ?? stack.last else { return false }
        guard let mimeTypes else      { return true  }
        return mimeTypes.contains(item.mime)
    }
}


//MARK: - Move
extension Google_DriveDelegate {
    func canDrag(file:GTLRDrive_File) -> Bool {
        guard let driveID = file.driveId else { return false }
        return file.id != driveID
    }
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
        let prior = files[index]
        do {
            moveItemIDs.append(newParentID)
            files.remove(at: index)
            if selected == files[index] {
                selected = nil
            }
            
            _ = try await Google_Drive.shared.move(fileID: id, from:currentParentID, to: newParentID)
        
            moveItemIDs.removeAll(where: {$0 == newParentID})
        } catch {
            moveItemIDs.removeAll(where: {$0 == newParentID})
            files.append(prior)
            sortFiles()
            throw error
        }
    }
}


//MARK: - New Folder
import BOF_SecretSauce
extension Google_DriveDelegate {
    var canCreateNewFolder : Bool {
        stack.last != nil
    }
    func createNewFolder(_ name:String, parentID:String) async throws  {
        do {
            let newFolder = try await Google_Drive.shared.create(folder: name, in:parentID)
             files.append(newFolder)
            sortFiles()
        } catch {
            throw error
        }
    }
    @ViewBuilder var newFolderView : some View {
        TextSheet(title: "New Folder", prompt: "Create") { name in
            do {
                guard let parentID = self.stack.last?.id else { throw NSError.quick("No Parent ID")}
                try await self.createNewFolder(name, parentID:parentID)
                return nil
            } catch {
                return error
            }
        }
    }
}


//MARK: - Rename
extension Google_DriveDelegate {
    func canRename(file:GTLRDrive_File?) -> Bool {
        guard let file                  else { return false }
        guard let dID = file.driveId    else { return false }
        guard file.id != dID            else { return false }
        return file != stack.last
    }
    func rename(_ name:String, id:String) async throws {
        do {
            let renamedFile = try await Google_Drive.shared.rename(id: id, newName: name)
            if let index = files.firstIndex(where: {$0.id == id}) {
                files.remove(at: index)
                files.append(renamedFile)
                sortFiles()
            }
        } catch {
            throw error
        }
    }
    @ViewBuilder func renameView(_ item:GTLRDrive_File) -> some View {
        TextSheet(title: "Rename", prompt: "Save", string:item.title) { newName in
            do { try await self.rename(newName, id:item.id); return nil}
            catch { return error }
        }
    }
}


//MARK: - Share
extension Google_DriveDelegate {
    func canShare(file:GTLRDrive_File?) -> Bool {
        guard file != nil else { return false }
        return file != stack.last
    }
    @ViewBuilder func shareView(_ item:GTLRDrive_File) -> some View {
        Google_Drive_Permissions(file: item)
    }
}


//MARK: - Delete
extension Google_DriveDelegate {
    func canDelete(file:GTLRDrive_File?) -> Bool {
        guard let file                  else { return false }
        guard let dID = file.driveId    else { return false }
        guard file.id != dID            else { return false }
        return file != stack.last
    }
    func delete(id:String) async throws {
        guard let index = files.firstIndex(where: {$0.id == id }) else { return }
        do {
            if selected == files[index] {
                selected = nil
            }
            guard try await Google_Drive.shared.delete(ids: [id]) else { return }
            files.remove(at: index)
        } catch {
            throw error
        }
    }
    @ViewBuilder func deleteView(_ item:GTLRDrive_File) -> some View {
        ConfirmationSheet(title: "Move '\(item.title)' to Trash",
                          message: "Google Drive will permanently delete this \(item.isFolder ? "folder": "file") in 30 days.  Prior to deletion, '\(item.title)', can be restored from Drive's Trash folder.",
                          prompt: "Move to trash") {
            do {
                try await self.delete(id:item.id)
            } catch { throw error }
        }
    }
}


//MARK: - Download
extension Google_DriveDelegate {
    func canDownload(file:GTLRDrive_File?) -> Bool {
        guard let file               else { return false }
        guard !file.isFolder         else { return false }
        guard !file.isShortcutFolder else { return false }
        guard let dID = file.driveId else { return false }
        guard file.id != dID         else { return false }
        return file != stack.last
    }
    func download(_ file:GTLRDrive_File) async {
        do {
            downloadItems.append(.init(file: file))
            let download = try await Google_Drive.shared.download(file) { progress in
                if let index = self.downloadItems.firstIndex(where: {$0.id == file.id }) {
                    self.downloadItems[index].progress = progress
                }
            }
            downloadData = download
            downloadFilename = file.downloadFilename
            showDownloadExport = true
            _ = downloadItems.remove(id:file.id)
        } catch {
            _ = downloadItems.remove(id:file.id)
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
    struct DownloadItem : Identifiable {
        var id       : String { file.id }
        let file     : GTLRDrive_File
        var error    : Error?
        var progress : Float = 0
    }
}


//MARK: - Upload
extension Google_DriveDelegate {
    func canUpload(to folder:GTLRDrive_File?) -> Bool {
        guard let folder      else { return false }
        guard folder.isFolder else { return false }
        return true
    }

    func upload(_ urls:[URL], to folder:GTLRDrive_File?) {
        guard let folder else { return }
        let parentID = folder.id
        guard  !parentID.isEmpty else { return }
        for url in urls {
            Task {
                _ = url.startAccessingSecurityScopedResource()
                
                let uploadItem : UploadItem
                
                if folder == stack.last {
                    //uploading into the main displayed folder
                    uploadItem = UploadItem(id:url.absoluteString, title:url.lastPathComponent)
                    let temporaryFile = GTLRDrive_File()
                    temporaryFile.identifier = url.absoluteString
                    temporaryFile.name = url.lastPathComponent
                    temporaryFile.mimeType = url.fileType
                    self.files.append(temporaryFile)
                    sortFiles()
                } else { //uploading to a folder in the main display
                    uploadItem =   UploadItem(id:folder.id, title:folder.title)
                }
            
                
                uploadItems.append(uploadItem)
                let uploadedFile =  try await Google_Drive.shared.upload(url:url, toParentID: parentID) { progress in
                    if let index = self.uploadItems.firstIndex(where: {$0.id == uploadItem.id}) {
                        self.uploadItems[index].progress = progress
                    }
                }
                
                if let index = files.firstIndex(where: {$0.id == url.absoluteString}) {
                    self.files.remove(at: index)
                    self.files.insert(uploadedFile, at: index)
                }
                
                _ = uploadItems.remove(id: uploadItem.id)
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
    struct UploadItem : Identifiable {
        var id       : String
        var title    : String
        var progress : Float = 0
    }
}
