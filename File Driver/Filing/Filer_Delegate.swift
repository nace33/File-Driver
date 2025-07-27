//
//  Filer_Delegate.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/21/25.
//

import Foundation
import GoogleAPIClientForREST_Drive


@Observable
final class Filer_Delegate {
    init(mode:Mode = .cases, actions:[Action] = Action.allCases) {
        self.mode = mode;
        self.actions = actions
    }
    
    //Mode
    enum Mode : String, CaseIterable { case cases, folders }
    var mode                : Mode {
        didSet {
            switchedMode()
        }
    }
    
    //Actions
    enum Action : String, CaseIterable {
        case newCase, newDrive, newFolder, filterCases, filterDrive, filterFolders, cancel, reset, saveTo
        static var inlineActions : [Action] { [.newCase, .newDrive, .newFolder, .filterCases, .filterDrive, .saveTo, .reset ]}
        static var sheetActions : [Action]  { [.newCase, .newDrive, .newFolder, .filterCases, .filterDrive, .saveTo, .cancel ]}
    }
    var actions : [Action]
    
    //Items
    var items       : [Filer_Item]       = [] { didSet { Task { await checkForItemsToDownload()}} }
    var tasks       : [Case.Task]        = []
    var tags        : [Case.Tag]         = []
    var contacts    : [Case.Contact]     = []
    var contactData : [Case.ContactData] = []
    
    //Cases
    private(set) var cases               : [Case] = []
    private(set) var caseCategories      : [Case.DriveLabel.Label.Field.Category] = []
    private(set) var selectedCase        : Case?
                 var caseListSelection   : Case?
    private(set) var caseListScrollID    : Case.ID?
    
    //Folders
    private(set) var stack               : [GTLRDrive_File] = []
    private(set) var folders             : [GTLRDrive_File] = []
    private(set) var selectedFolder      : GTLRDrive_File?
                 var folderListSelection : GTLRDrive_File?
    private(set) var folderListScrollID  : GTLRDrive_File.ID?
    
    //Status
    var loader              = VLoader_Item()

    //Filter
    var filterString = ""
}


//MARK: - General
extension Filer_Delegate {
    var canFileItems : Bool {
        guard items.count > 0 else { return false }
        guard canShowForm else { return false }
        return items.allSatisfy { item in
            guard item.filename.count > 0 else { return false }
            guard item.status == .readyToFile else { return false }
            return true
        }
    }
    var canSelectItem : Bool {
        switch mode {
        case .cases:
            if selectedCase == nil { caseListSelection != nil }
            else { folderListSelection != nil }
        case .folders:
            folderListSelection != nil
        }
    }
    var canShowForm : Bool {
        switch mode {
        case .cases:
            selectedCase != nil && selectedFolder != nil
        case .folders:
            selectedFolder != nil
        }
    }
    var canReset : Bool {
        switch mode {
        case .cases:
            selectedCase != nil
        case .folders:
            selectedFolder != nil
        }
    }
    func switchedMode() {
        resetCaseVariables()
        resetFolderVariables()
        Task { await load() }
    }
    func load() async {
        switch mode {
        case .cases:
            await loadCases()
        case .folders:
            await loadFolders()
        }
    }
}


//MARK: - Cases
extension Filer_Delegate {
    func resetCaseSpreadsheetVariables() {
        tasks        = []
        tags         = []
        contacts     = []
        contactData  = []
    }
    func resetCaseVariables() {
        cases             = []
        selectedCase      = nil
        caseListSelection = nil
        caseListScrollID  = nil
        filterString      = ""
        resetCaseSpreadsheetVariables()
    }
    func addNewCase(_ newCase:Case) {
        cases.append(newCase)
        cases.sort(by: {$0.title.lowercased() < $1.title.lowercased()})
        caseCategories = cases.compactMap { $0.label.category}
                              .unique()
                              .sorted(by: {$0.intValue < $1.intValue})
       
        caseListSelection   = newCase
        caseListScrollID    = newCase.id
    }
    func loadCases() async {
        do {
            resetCaseVariables()
            resetFolderVariables()
            loader.start()
            loader.status = "Loading Cases"
            cases = try await Case.allCases()
        
            caseCategories = cases.compactMap { $0.label.category}
                                  .unique()
                                  .sorted(by: {$0.intValue < $1.intValue})
            
            loader.stop()
        } catch {
            loader.stop(error)
        }
    }
    func loadCase(_ aCase:Case) async {
        do {
            loader.status = "Loading \(aCase.title)"
            loader.start()
            try await aCase.load(sheets: [.contacts, .contactData, .folders, .tags, .files])
            loader.stop()
        } catch {
            loader.stop(error)
        }
    }
    func select(_ aCase:Case)  {
        selectedCase = aCase
//        loader.start()
        stack = [aCase.parentFolder]
        
        Task { await loadFolders() }
    }
    func select(_ suggestion:FilerSuggestion) {
        if let aCase = cases.first(where: {$0.id == suggestion.filerCase.spreadsheetID}) {
            //do not call select(_ aCase) because we do not want to loadFolders()
            selectedCase = aCase
            let folder = GTLRDrive_File()
            folder.mimeType = GTLRDrive_File.MimeType.folder.rawValue
            folder.name = suggestion.selectedFolder.name
            folder.identifier = suggestion.selectedFolder.folderID
            stack = [aCase.parentFolder, folder]
            selectedFolder = folder
            Task { await loadCase(aCase)}
        }
    }
}


//MARK: - Folders
extension Filer_Delegate {
    func resetFolderVariables() {
        selectedFolder      = nil
        folderListSelection = nil
        folderListScrollID  = nil
        stack               = []
        filterString        = ""
    }
    func addNewFolder(_ name:String) async throws {
        do {
            let newFolder : GTLRDrive_File
            if let parentID = stack.last?.id {
                newFolder = try await Drive.shared.create(folder: name, in:parentID)
            } else {
                newFolder = try await Drive.shared.sharedDrive(new: name)
                                                  .asFolder
            }
            folders.append(newFolder)
            folders.sort { $0.title.ciCompare($1.title)}
            folderListSelection = newFolder
            folderListScrollID = newFolder.id
        } catch {
            throw error
        }
    }
    func load(_ folder:GTLRDrive_File) {
        if !stack.contains(folder) {
            stack.append(folder)
            Task { await loadFolders() }
        }
    }
    func popTo(_ folder:GTLRDrive_File) {
        if let index = stack.firstIndex(where: {$0.id == folder.id}) {
            stack.removeSubrange(index+1..<stack.count)
            Task { await loadFolders() }
        }
    }
    func loadFolders() async {
        do {
            loader.start()
            filterString      = ""
            loader.status = "Loading Folders"
            selectedFolder = nil
            folders = try await Drive.shared.getContents(of:stack.last?.id, onlyFolders: true)
            loader.stop()
           
            if stack.count > 1 {
                folderListSelection = stack.last
            } else {
                folderListSelection = nil
            }
        } catch {
            loader.stop(error)
        }
    }
    func select(_ folder:GTLRDrive_File) {
        if !stack.contains(folder) {
            stack.append(folder)
        }
        selectedFolder = folder
        Task {
            if let selectedCase {
                await loadCase(selectedCase)
            }
        }
    }
}


//MARK: Download
///Download and/or print to PDF
import BOF_SecretSauce
extension Filer_Delegate {
    func checkForItemsToDownload() async {
        let itemsToDownload = items.filter { $0.status != .readyToFile}
        guard itemsToDownload.isNotEmpty else { return }
        let autoRename = UserDefaults.standard.bool(forKey:BOF_Settings.Key.filingAutoRename.rawValue)
        do {
            loader.start()
            for item in itemsToDownload {
                let downloadTitle = "Downloading \(item.filename)"
                loader.status = downloadTitle
                switch item.category {
                case .driveFile, .localURL:
                    continue
                case .remoteURL:
                    if let remoteURL = item.remoteURL {
                        let url  = try await URLSession.download(remoteURL, to: URL.downloadsDirectory) {
                            self.loader.progress = $0
                            if self.loader.status != downloadTitle { self.loader.status = downloadTitle }
                        }
                        await processDownload(of:url, for: item, autoRename: autoRename)
                    }
                case .remotePDFURL:
                    if let remoteURL = item.remoteURL {
                        let url = try await WebViewToPDF.print(url:remoteURL, saveTo: URL.downloadsDirectory) {
                            self.loader.progress = $0
                            if self.loader.status != downloadTitle { self.loader.status = downloadTitle }
                        }
                        await processDownload(of:url, for: item, autoRename: autoRename)
                    }
                }
            }
            loader.stop()
        } catch {
            loader.stop(error)

        }
    }
    @MainActor func processDownload(of url:URL, for item:Filer_Item, autoRename:Bool) {
        let emailThread = url.emailThread
        
        if autoRename,
            let renamedURL = try? AutoFile_Rename.autoRenameLocalFile(url: url, thread:emailThread) {
            item.localURL = renamedURL
        } else {
            item.localURL = url
        }
        item.category = .localURL
        item.emailThread = emailThread
        item.status = .readyToFile
        item.filename = item.localURL!.deletingPathExtension().lastPathComponent
    }
}



//MARK: - Filing
extension Filer_Delegate {
    //Delete Local Files
    fileprivate func trashLocalFile(for item:Filer_Item) {
        if let localURL = item.localURL {
            try? FileManager.default.trashItem(at: localURL, resultingItemURL: nil)
        }
    }
    
    //Upload Item
    fileprivate func upload(_ uploadItem:Filer_Item, to folderID:String) async throws {
        loader.status = "Uploading \(uploadItem.filename)"
        let appProp = uploadItem.emailThread?.driveAppProperties
        let uploadedFile = try await Drive.shared.upload(url:uploadItem.localURL!, filename:uploadItem.filename, to:folderID, appProperties:appProp) { progress in
            self.loader.progress = progress
        }
        uploadItem.file = uploadedFile
        trashLocalFile(for:uploadItem)
        uploadItem.status = .filed
    }
    
    //Move item already in drive
    fileprivate func move(_ moveItems:[Filer_Item],  to folderID:String) async throws {
        do {
            loader.status  = moveItems.count == 1 ? "Moving: \(moveItems[0].filename)" : "Moving \(moveItems.count) files"
            for item in items {
                item.file?.name = item.filename
            }
            _ = try await Drive.shared.move(files: moveItems.compactMap(\.file), to: folderID)
            
            for moveItem in moveItems {
                moveItem.status = .filed
                moveItem.file?.parents = [folderID]
            }
        } catch {
            throw error
        }
    }
    
    //Update Spreadsheet
    fileprivate func updateSpreadsheet(for aCase:Case) async throws {
        loader.status = "Updating \(aCase.title)"
        //Create sheetRows
        var rows = [any SheetRow]()

        let usedFolders = stack.compactMap{ Case.Folder(file: $0)}
        let newFolders  = usedFolders.filter { !aCase.isInSpreadsheet($0.folderID, sheet: .folders)}
//        print("New Folders: \(newFolders)")
        
        rows    += newFolders

        let newFiles : [Case.File] = items.compactMap { item in
            guard let file = item.file else { return nil }
            return Case.File(fileID:file.id,
                             name: file.titleWithoutExtension,
                             mimeType: file.mime.rawValue,
                             fileSize: file.fileSizeString,
                             folderID: selectedFolder?.id ?? "",
                             contactIDs: contacts.map(\.id),
                             tagIDs: tags.map(\.id),
                             idDateString: Date.idString)
        }
//        print("New Files: \(newFiles)")
        rows    += newFiles
        
        let newContacts = contacts.filter {!aCase.isInSpreadsheet($0.id, sheet: .contacts)}
//        print("New Contacts: \(newContacts)")
        rows    += newContacts
        
        let newContactData = contactData.filter  {!aCase.isInSpreadsheet($0.id, sheet: .contactData)}
//        print("New Contact Data: \(newContactData)")
        rows    += newContactData
        
        let newTags = tags.filter {!aCase.isInSpreadsheet($0.id, sheet: .tags)}
//        print("New Tags: \(newTags)")
        rows    += newTags
        
        let newTasks = tasks.filter {!aCase.isInSpreadsheet($0.id, sheet: .tasks)}
//        print("New Tasks: \(newTasks)")
        rows    += newTasks
        
        do {
            guard rows.count > 0 else { throw NSError.quick("No spreadsheet data to add")}
            //Update Spreadsheet
            try await Sheets.shared.append(rows, to:aCase.id)
            
            //Update local model
            aCase.folders.append(contentsOf: newFolders)
            aCase.files.append(contentsOf: newFiles)
            aCase.contacts.append(contentsOf: newContacts)
            aCase.contactData.append(contentsOf: newContactData)
            aCase.tags.append(contentsOf: newTags)
            aCase.tasks.append(contentsOf: newTasks)
            
            //Update Swift Data Model
            //do not use 'New' items (except files) since SwiftData is tracking relationships
            guard let filedToFolder = usedFolders.last else { print("Unable to update Swift Data because no folder was found."); return}
            //make sure contactData is included in what is sent to Swift Data
            await updateSwiftData(aCase: aCase, folders: [filedToFolder], contacts: contacts, data: contactData, files: newFiles, tags: tags)
        } catch {
            throw error
        }
    }

    
    //Calls
    func trashLocalFiles() {
        for item in items {
            trashLocalFile(for: item)
        }
    }
    func saveTo(_ folderID:String) async throws {
        do {
            loader.start()
            
            //upload Items
            let uploadItems = self.items.filter({ $0.status == .readyToFile && $0.localURL != nil  })
            if uploadItems.count > 0 {
                for uploadItem in uploadItems {
                    try await upload(uploadItem, to:folderID)
                }
            }
            
            //Move Items - already in Drive
            let moveItems = self.items.filter({$0.status == .readyToFile && $0.category == .driveFile && $0.file?.parents?.first != folderID})
            if moveItems.count > 0 {
                try await move(moveItems, to: folderID)
            }
            
            loader.stop()
        } catch {
            loader.stop(error)
            throw error
        }
    }
    func saveToSelectedCase() async throws {
        do {
            guard let aCase  = selectedCase   else { throw NSError.quick("No Case Selected"  ) }
            guard let folder = selectedFolder else { throw NSError.quick("No Folder Selected") }
            
            //Save the items to the appropriate directory
   
            try await saveTo(folder.id)
            
            //Update the Case Spreadsheet
            try await updateSpreadsheet(for: aCase)
        } catch {
            throw error
        }
    }
}



//MARK: - Local Model Updates
extension Filer_Delegate {
    @MainActor func updateSwiftData(aCase:Case, folders:[Case.Folder], contacts:[Case.Contact], data:[Case.ContactData], files:[Case.File], tags:[Case.Tag] ) {
        let filerCase = FilerCase.get(aCase)
        filerCase.append(folders: folders, contacts: contacts, data: contactData, files: files, tags: tags, save: true)
    }
}
