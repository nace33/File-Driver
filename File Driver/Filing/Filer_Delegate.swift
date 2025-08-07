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
    init(modes:[Mode] = [.cases, .folders], actions:[Action] = Action.allCases) {
        self.modes = modes
        self.selectedMode = modes.first ?? .cases
        self.actions = actions
    }
    
    //Mode
    enum Mode : Equatable, Hashable {
        case cases, folders, aCase(Case)
        var title : String {
            switch self {
            case .cases:
                "Cases"
            case .folders:
                "Folders"
            case .aCase(let aCase):
                aCase.title
            }
        }
    }
    var modes        : [Mode] {
        didSet {
            switchedMode()
        }
    }
    var selectedMode : Mode {
        didSet {
            switchedMode()
        }
    }
    var isInSingleCaseMode : Bool {
        guard modes.count == 1, let onlyMode = modes.first else { return false }
        return switch onlyMode {
        case .cases, .folders:
            false
        case .aCase(_):
            true
        }
    }

    //Actions
    enum Action : String, CaseIterable {
        case newCase, newDrive, newFolder, filterCases, filterDrive, filterFolders, cancel, reset, saveTo, trash
        static var inlineActions : [Action]  { [.newCase, .newDrive, .newFolder, .filterCases, .filterDrive, .saveTo, .reset, .trash  ]}
        static var sheetActions  : [Action]  { [.newCase, .newDrive, .newFolder, .filterCases, .filterDrive, .saveTo, .cancel, .trash  ]}
        static var altSheetActs  : [Action]  { [.newCase, .newDrive, .newFolder, .filterCases, .filterDrive, .cancel , .trash          ]} //no saveTo
    }
    var actions : [Action]
    
    //Items
    var items       : [Filer_Item]       = [] { didSet { Task { await checkForItemsToDownload()}} }
    var tasks       : [Case.Task]        = []
    var tags        : [Case.Tag]         = []
    var contacts    : [Case.Contact]     = []
    var contactData : [Case.ContactData] = []
    var trackers    : [Case.Tracker] = []
    
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
    
    
    //Trackers
    var oneTrackerPerFile = false
    
    //Status
    var loader              = VLoader_Item()
    
    enum FilingState : Equatable{
        static func == (lhs: Filer_Delegate.FilingState, rhs: Filer_Delegate.FilingState) -> Bool { lhs.intValue == rhs.intValue   }
        case idle, caseSelected(Case), folderSelected(GTLRDrive_File), formPresented, isFiling, filed([Filer_Item], Bool), caseUpdated(Case), error(Error)
        var intValue : Int {
            switch self {
            case .idle:
                0
            case .caseSelected(_):
                1
            case .folderSelected(_):
                2
            case .formPresented:
                3
            case .isFiling:
                4
            case .filed(_, _):
                5
            case .caseUpdated(_):
                6
            case .error(_):
                -1
            }
        }
        var title : String {
            switch self {
            case .idle:
                "Idle"
            case .caseSelected(let aCase):
                "Selected Case: \(aCase.title)"
            case .caseUpdated(let aCase):
                "Updated Case: \(aCase.title)"
            case .folderSelected(let folder):
                "Selected Folder: \(folder.name ?? "Untitled Folder")"
            case .formPresented:
                "Form Presented"
            case .isFiling:
                "Filing"
            case .filed(_,_):
                "Success"
            case .error(_):
                "Error"
            }
        }
    }
    private(set) var filingState : FilingState = .idle
    
    
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
        switch selectedMode {
        case .cases:
            if selectedCase == nil { caseListSelection != nil }
            else { folderListSelection != nil }
        case .folders:
            folderListSelection != nil
        case .aCase(_):
            folderListSelection != nil
        }
    }
    var canShowForm : Bool {
        switch selectedMode {
        case .cases:
            selectedCase != nil && selectedFolder != nil
        case .folders:
            selectedFolder != nil
        case .aCase(_):
            selectedFolder != nil
        }
    }
    func setFilingState(_ state: FilingState) {
        self.filingState = state
    }
    var canReset : Bool {
        switch selectedMode {
        case .cases:
            selectedCase != nil
        case .folders:
            selectedFolder != nil
        case .aCase(_):
            selectedFolder != nil
        }
    }
    func switchedMode() {
        resetCaseVariables()
        resetFolderVariables()
        Task { await load() }
    }
    func load() async {
        switch selectedMode {
        case .cases:
            await loadCases()
        case .folders:
            await loadFolders()
        case .aCase(let aCase):
            select(aCase)
        }
    }
}


//MARK: - Cases
extension Filer_Delegate {
    func resetFormData() {
        tasks             = []
        tags              = []
        contacts          = []
        contactData       = []
        trackers          = []
        oneTrackerPerFile = false
    }
    func resetCaseVariables() {
        cases             = []
        selectedCase      = nil
        caseListSelection = nil
        caseListScrollID  = nil
        filterString      = ""
        resetFormData()
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
            filingState = .idle
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
            try await aCase.load(sheets: [.contacts, .contactData, .folders, .tags, .files, .trackers])
            loader.stop()
        } catch {
            loader.stop(error)
        }
    }
    func select(_ aCase:Case)  {
        filingState = .caseSelected(aCase)
        selectedCase = aCase
//        loader.start()
        stack = [aCase.parentFolder]
        
        Task { await loadFolders() }
    }
    func select(_ suggestion:FilerSuggestion, presentFilingForm:Bool) {
        if let aCase = cases.first(where: {$0.id == suggestion.filerCase.spreadsheetID}) {
            //do not call select(_ aCase) because we do not want to loadFolders()
            if presentFilingForm {//select case and folder and present filing form
                selectedCase = aCase
                let folder = GTLRDrive_File()
                folder.mimeType = GTLRDrive_File.MimeType.folder.rawValue
                folder.name = suggestion.selectedFolder.name
                folder.identifier = suggestion.selectedFolder.folderID
                stack = [aCase.parentFolder, folder]
                selectedFolder = folder
                Task { await loadCase(aCase)}
            } else {//normal case selection
                select(aCase)
            }
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
            filingState = .idle
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
        filingState = .folderSelected(folder)
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
                        await processDownload(of:url, for: item)
                    }
                case .remotePDFURL:
                    if let remoteURL = item.remoteURL {
                        let url = try await WebViewToPDF.print(url:remoteURL, saveTo: URL.downloadsDirectory) {
                            self.loader.progress = $0
                            if self.loader.status != downloadTitle { self.loader.status = downloadTitle }
                        }
                        await processDownload(of:url, for: item)
                    }
                }
            }
            loader.stop()
        } catch {
            loader.stop(error)

        }
    }
    @MainActor func processDownload(of url:URL, for item:Filer_Item) {
        let emailThread = url.emailThread
        let autoRenameFiles = UserDefaults.standard.bool(forKey:BOF_Settings.Key.filingAutoRenameFiles.rawValue)
        let autoRenameEmails = UserDefaults.standard.bool(forKey:BOF_Settings.Key.filingAutoRenameEmails.rawValue)
        if (autoRenameFiles || autoRenameEmails),
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
        if actions.contains(.trash), let localURL = item.localURL {
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
        uploadItem.filedToCase = selectedCase
    }
    
    //Move items already in drive
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
                moveItem.filedToCase = selectedCase
            }
        } catch {
            throw error
        }
    }
    
    //Copty items already in drive
    fileprivate func copy(_ copyItems:[Filer_Item],  to folderID:String) async throws {
        do {
            loader.status  = copyItems.count == 1 ? "Copying: \(copyItems[0].filename)" : "Copying \(copyItems.count) files"
            for item in items {
                item.file?.name = item.filename
            }
            _ = try await Drive.shared.copy(files: copyItems.compactMap(\.file), to: folderID)
            
            for copyItem in copyItems {
                copyItem.status = .filed
                copyItem.file?.parents = [folderID]
                copyItem.filedToCase   = selectedCase
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

        let usedFolders = stack.compactMap{
            Case.Folder(googleDriveFile: $0)
        }
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
        
        //update trackers with appropriate IDs
        for (index, _) in trackers.enumerated() {
           trackers[index].contactIDs = contacts.map(\.id)
           trackers[index].tagIDs = tags.map(\.id)
           trackers[index].fileIDs = newFiles.map(\.fileID)
        }
        
        let newTrackers : [Case.Tracker]
        if oneTrackerPerFile, let templateTracker = trackers.first {
            newTrackers = newFiles.compactMap( { newFile in
                Case.Tracker(catString: templateTracker.catString, status: templateTracker.status, contactIDs: templateTracker.contactIDs, tagIDs: templateTracker.tagIDs, fileIDs: [newFile.fileID], text: templateTracker.text)
            })
        } else {
            newTrackers = trackers.filter {!aCase.isInSpreadsheet($0.id, sheet: .trackers) }
        }
        
        rows    += newTrackers
        
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
            aCase.trackers.append(contentsOf: newTrackers)
            
            filingState = .caseUpdated(aCase)
            
            //Update Swift Data Model
            //do not use 'New' items (except files) since SwiftData is tracking relationships
            guard let filedToFolder = usedFolders.last else { print("Unable to update Swift Data because no folder was found."); return}
            //make sure contactData is included in what is sent to Swift Data
                    
            loader.status = "Updating Suggestions"
            await updateSwiftData(aCase: aCase, folders: [filedToFolder], contacts: contacts, data: contactData, files: newFiles, tags: tags)
        } catch {
            throw error
        }
    }

    
    //Calls
    func clearError() {
        loader.clearError()
        filingState = .idle
    }
    func reset(reload:Bool) {
        if reload {//reset everything
            resetCaseVariables()
            resetFolderVariables()
            Task { await self.load() }
        } else {//just clear selection and form data, do not trigger network call
            stack = []
            selectedCase = nil
            selectedFolder = nil
            caseListSelection = nil
            caseListScrollID  = nil
            folderListSelection = nil
            folderListScrollID = nil
            filterString      = ""
            resetFormData()
        }
    }
    func trashLocalFiles() {
        for item in items {
            trashLocalFile(for: item)
        }
    }
    func saveTo(_ folderID:String) async throws {
        do {
            loader.start()
            filingState = .isFiling
            //upload Items
            let uploadItems = self.items.filter({ $0.status == .readyToFile && $0.localURL != nil  })
            if uploadItems.count > 0 {
                for uploadItem in uploadItems {
                    try await upload(uploadItem, to:folderID)
                }
            }
            
            //Move Items - already in Drive
            let moveItems = self.items.filter({$0.status == .readyToFile && $0.category == .driveFile && $0.file?.parents?.first != folderID && $0.fileAction == .move})
            if moveItems.count > 0 {
                try await move(moveItems, to: folderID)
            }
            
            //Copy Items - already in Drive
            let copyItems = self.items.filter({$0.status == .readyToFile && $0.category == .driveFile && $0.file?.parents?.first != folderID && $0.fileAction == .copy})
            if copyItems.count > 0 {
                try await copy(copyItems, to: folderID)
            }
            
            
            loader.stop()
            let filedItems = self.items.filter({$0.status == .filed})
            let allFiled   = self.items.allSatisfy { $0.status == .filed  }
            filingState = .filed(filedItems, allFiled)
        } catch {
            loader.stop(error)
            filingState = .error(error)
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
