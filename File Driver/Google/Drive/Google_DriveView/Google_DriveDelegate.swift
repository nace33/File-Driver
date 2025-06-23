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
class Google_DriveDelegate  {
    init(rootID:String? = nil, actions: [Google_DriveDelegate.Action] = [.refresh], labelIDs:[String]? = nil, mimeTypes:[GTLRDrive_File.MimeType]? = nil) {
        self.actions = actions
        self.labelIDs = labelIDs
        self.mimeTypes = mimeTypes
        self.rootID = rootID
    }
    static func selecter(labelIDs:[String]? = nil, mimeTypes:[GTLRDrive_File.MimeType]? = nil) -> Google_DriveDelegate {
        Google_DriveDelegate(actions: [.select], labelIDs: labelIDs, mimeTypes: mimeTypes)
    }
    static func deluxe(labelIDs:[String]? = nil, mimeTypes:[GTLRDrive_File.MimeType]? = nil)   -> Google_DriveDelegate {
        Google_DriveDelegate(actions:Google_DriveDelegate.Action.allCases, labelIDs: labelIDs, mimeTypes: mimeTypes)
    }
    
    var rootID : String?
    var doubleClicked : GTLRDrive_File?  = nil
//    var selected      : GTLRDrive_File?  = nil
    var selection          : Set<GTLRDrive_File>  = []
    internal var files  : [GTLRDrive_File] = []
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
    var renameItem       : RenameItem?  = nil
    var selectItem       : GTLRDrive_File?  = nil
    var shareItem        : GTLRDrive_File?  = nil
    var deleteItem       : DeleteItem? = nil
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

//MARK: - List
extension Google_DriveDelegate {
    func removeFromSelection(_ files: [GTLRDrive_File]) {
        let fileIds     = files.compactMap {$0.id}
        for fileId in fileIds {
            if let index = selection.firstIndex(where: {$0.id == fileId}){
                selection.remove(at: index)
            }
        }
    }
    internal func sortFiles() {
        files.sort { $0.title.ciCompare($1.title)}
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
extension Google_DriveDelegate {
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
            selectItem = nil
            doubleClicked = nil
            stackWillReloadSoon = false
            selection = []
            if let customLoad {//currently only a customLoad is set in Google_DriveView.task(id:...)
                load = customLoad //save reference so other functions that call this (i.e. refresh) call the custom load
                files = try await customLoad()
            }
            else if let load {//this load call is set above, originally passed in from Google_DriveView.task(id:...)
                files = try await load()
            }
            else if let last = stack.last, last.isFolder {
                files = try await Google_Drive.shared.getContents(of: last.id, labelIDs: labelIDs, onlyFolders: onlyFolders)
                                                     .filter { validatedMimeTypes?.contains($0.mime) ?? true }
            } else if let rootID {
                let root = try await Google_Drive.shared.get(fileID: rootID, labelIDs: labelIDs)
                guard root.isFolder else { throw NSError.quick("Root is not a folder")}
                addToStack(root)
            }
            else {
                files = try await Google_Drive.shared.sharedDrivesAsFolders()
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
}


//MARK: - Actions
extension Google_DriveDelegate {
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
        case .move, .filter:
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

