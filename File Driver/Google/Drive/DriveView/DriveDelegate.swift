//
//  Google.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

@Observable
public
class DriveDelegate  {
    init(rootID:String? = nil, actions: [DriveDelegate.Action] = [.refresh], labelIDs:[String]? = nil, mimeTypes:[GTLRDrive_File.MimeType]? = nil, fields: [GTLRDrive_Label_Fields]? = nil) {
        self.actions = actions
        self.labelIDs = labelIDs
        self.mimeTypes = mimeTypes
        self.fields = fields
        self.rootID = rootID
    }
    static func selecter(labelIDs:[String]? = nil, mimeTypes:[GTLRDrive_File.MimeType]? = nil) -> DriveDelegate {
        DriveDelegate(actions: [.select], labelIDs: labelIDs, mimeTypes: mimeTypes)
    }
    static func deluxe(labelIDs:[String]? = nil, mimeTypes:[GTLRDrive_File.MimeType]? = nil)   -> DriveDelegate {
        DriveDelegate(actions:DriveDelegate.Action.allCases, labelIDs: labelIDs, mimeTypes: mimeTypes)
    }
    
    var rootID            : String?
    var fields            : [GTLRDrive_Label_Fields]? = nil
    var doubleClicked     : GTLRDrive_File?  = nil
    var selection         : Set<GTLRDrive_File>  = []
    internal var files    : [GTLRDrive_File] = []
    private(set)var stack : [GTLRDrive_File] = []
    
    //Filter
    var filter      = ""
    
    //Loading
    typealias customLoader = () async throws->[GTLRDrive_File]
    private(set)var load        : customLoader?
    private(set)var isLoading   = true //only set in loadStack()
    //Useful when DriveView, custom list is used to syncrhomize sequences of loading for views.  Otherwise, a list can load, then a view displays before it is ready
    private(set)var stackWillReloadSoon : Bool   = false //Set to signal reload is about to occur.  Set to false in load after isLoading is set to true and reloading begins
    var error       : Error?
    var labelIDs    : [String]?
    var mimeTypes   : [GTLRDrive_File.MimeType]?
    
    
    
    //Actions
    var actions          : [DriveDelegate.Action]
    var renameItem       : RenameItem?  = nil
    var selectItem       : GTLRDrive_File?  = nil
    var shareItem        : GTLRDrive_File?  = nil
    var deleteItem       : DeleteItem? = nil
    var uploadToFolder   : GTLRDrive_File?  = nil
    var showUploadSheet  = false

    //var Sort
    var sortBy: SortBy {
        get {
            let string = UserDefaults.standard.object(forKey: "Google_Drive_SortFilesKey") as? String ?? SortBy.ascending.rawValue
            return SortBy(rawValue: string) ?? .ascending
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "Google_Drive_SortFilesKey")
            sortFiles()
        }
    }

    
    
    //Move
    var moveItemIDs      : [String]  = []
    
    //Downloading
    var downloadItems    : [DriveDelegate.DownloadItem]  = []
    var downloadData     : Data?    = nil
    var downloadFilename : String?  = nil
    var showDownloadExport          = false
    var showNewFolderSheet          = false
    var moveSelectedFilesIntoFolder = false

    //Uploading
    var uploadItems      : [DriveDelegate.UploadItem]  = []
    
    
    public enum Action : String, CaseIterable {
        case select, rename, newFolder, move, share, upload, download, delete, refresh, filter, preview
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
            case .preview:
                "photo"
            }
        }
    }
}

//MARK: - List
extension DriveDelegate {

    func selectFirstItem() {
        selection.removeAll()
        if let firstFile = files.first {
            selection = [firstFile]
        }
    }
    func removeFiles(_ fileIDs:[String]) {
        self.files.removeAll(where: {  fileIDs.contains($0.id)  })
    }
    func filesWereRemoved(_ files:[GTLRDrive_File]) {
        let fileIds     = files.compactMap {$0.id}
        removeFromSelection(fileIds)
        removeFiles(fileIds)
    }
    func removeFromSelection(_ fileIDs: [String]) {
        for fileId in fileIDs {
            if let index = selection.firstIndex(where: {$0.id == fileId}){
                selection.remove(at: index)
            }
        }
    }
    func removeFromSelection(_ files: [GTLRDrive_File]) {
        let fileIds     = files.compactMap {$0.id}
        removeFromSelection(fileIds)
    }
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
extension DriveDelegate {
    func refresh() {
        Task {
            stackWillReloadSoon = true
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
            selection = []
            selectItem = nil
            doubleClicked = nil
            stackWillReloadSoon = false
            if let customLoad {//currently only a customLoad is set in DriveView.task(id:...)
                load = customLoad //save reference so other functions that call this (i.e. refresh) call the custom load
                files = try await customLoad()
            }
            else if let load {//this load call is set above, originally passed in from DriveView.task(id:...)
                files = try await load()
            }
            else if let last = stack.last, last.isFolder {
                files = try await Drive.shared.getContents(of: last.id, labelIDs: labelIDs, onlyFolders: onlyFolders)
                                                     .filter { validatedMimeTypes?.contains($0.mime) ?? true }
            } else if let rootID {
                let root = try await Drive.shared.get(fileID: rootID, labelIDs: labelIDs)
                guard root.isFolder else { throw NSError.quick("Root is not a folder")}
                addToStack(root)
            }
            else {
                files = try await Drive.shared.sharedDrivesAsFolders()
            }
            sortFiles()
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
        }
    }

    func sortFiles() {
//        print(#function)
        switch sortBy {
        case .ascending:
            files.sort { $0.title.ciCompare($1.title)}
        case .descending:
            files.sort { !$0.title.ciCompare($1.title) }
        case .lastModified:
            files.sort {
                guard let lhsDate = $0.modifiedTime?.date, let rhsDate = $1.modifiedTime?.date else {
                    return $0.title.ciCompare($1.title)
                }
                return lhsDate < rhsDate
            }
        case .fileType:
            files.sort { $0.mime.title.ciCompare($1.mime.title)}
        }
    }
}


//MARK: - Computed Properties
extension DriveDelegate {
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
}


//MARK: - Actions
extension DriveDelegate {
    var  availableActions : [Action] {   availableActions(for: selection)  }
    func availableActions(for files:Set<GTLRDrive_File>) -> [Action] {
        actions.filter { action in
           canPerform(action, on: files)
        }
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
        case .move, .filter, .preview:
            false
        }
    }
    func canPerform(_ action:Action, on files:Set<GTLRDrive_File>) -> Bool {
        if files.count == 0 {
            canPerform(action, on: nil)
        }
        else if files.count == 1 {
            files.allSatisfy{ canPerform(action, on: $0)}
        } else {
            files.allSatisfy { file in
                switch action {
                case .rename, .move, .delete, .newFolder:
                    canPerform(action, on: file)
                default:
                    false
                }
            }
        }
    }
    func perform(_ action:Action, on files:Set<GTLRDrive_File>)  {
        switch action {
        case .newFolder:
            performActionNewFolder()
        case .rename:
            performActionRename(files: files.sorted(by: {$0.title.ciCompare($1.title)}))
        case .delete:
            performActionDelete(files:files.sorted(by: {$0.title.ciCompare($1.title)}))
        case .share:
            performActionShare(files.first)
        case .download:
            performActionDownload(files.first)
        case .refresh:
            refresh()
        case .select:
            performActionSelect(files.first)
        case .upload:
            performActionUpload()
        default:
            print("Perform: \(action.title)")
            for file in files {
                print("  \(file.title)")
            }
//        case .upload:
//            <#code#>
        }

    }
}

