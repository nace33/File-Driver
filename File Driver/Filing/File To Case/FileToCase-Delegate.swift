//
//  Filer_Delegate.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/2/25.
//

import Foundation
import GoogleAPIClientForREST_Drive


@Observable
final class FileToCase_Delegate {
    var justFiled : [FileToCase_Item]? = nil
    
    var items : [FileToCase_Item] = [] {
        didSet {
            try? self.loadSuggestions()
        }
    }
    
    //Loading
    var isLoading : Bool   = true
    var isFiling  : Bool   = false
    var progress  : Double = 0.0
    var error     : Error?
    var status    : String = ""
    var filter    : String = ""
    
    //Selection
    var selectedCase        : Case?
    var selectedFolder      : GTLRDrive_File?
    var scrollToCaseID      : Case.ID? = nil
    var scrollToFolderID    : GTLRDrive_File.ID? = nil
    var selectedDestination : GTLRDrive_File?
    var stack               : [GTLRDrive_File] = [] {
        didSet {
            Task  { await load() }
        }
    }

    //Loading
    var byPassLoading = false
    var cases       : [Case] = []
    var suggestions : [FolderSuggestion] = []
    var categories  : [Case.DriveLabel.Label.Field.Category] = []
    var folders     : [GTLRDrive_File] = []
    

    //Filing Properties
    struct FileName : Identifiable, Hashable {
        let id : String
        var text : String
        init(_ file:GTLRDrive_File) {
            self.id = file.id
            self.text = file.titleWithoutExtension
        }
    }
    private(set) var filingTags        : [Case.Tag]          = []
    private(set) var filingContacts    : [Case.Contact]      = []
    private(set) var filingContactData : [Case.ContactData]  = []
    var filingTasks                    : [Case.Task]         = []
    
    var suggestionData : Suggestions.Data = .init(words: [], strings: [], contacts: [])

}


//MARK: - Computed Properties
extension FileToCase_Delegate {
    var showCasesList   : Bool { stack.isEmpty }
    var showFoldersList : Bool { !stack.isEmpty  && selectedDestination == nil }
    var filteredCases : [Case] {
        let hasFilter = filter.count > 0
        let suggestionIDs = suggestions.compactMap({$0.root?.id})
        guard hasFilter || suggestionIDs.count > 0  else { return cases }
        return cases.filter {
            if hasFilter, !$0.title.ciContain(filter) { return false }
            return !suggestionIDs.contains($0.id)
        }
    }
    var filteredFolders : [GTLRDrive_File] {
        guard filter.count > 0 else { return folders }
        return folders.filter { $0.title.ciContain(filter)}
    }
    var canAddToCase : Bool {
        guard selectedCase != nil,
                selectedDestination != nil,
                items.filter({ $0.filename.isEmpty}).isEmpty else { return false }
        return true
    }
}


//MARK: - Load
extension FileToCase_Delegate {
    func load() async {
        guard !byPassLoading else { return }
        do {
            error     = nil
            ///isLoading may already be set to true elsewhere to make UI look good
            ///see doubleClicked() methods below
            isLoading = true

            if selectedDestination != nil {
                try await loadSpreadsheet()
            }
            else if let last = stack.last {
                try await loadFolders(last)
            } else {
                try await loadCases()
            }
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
        }
    }
    fileprivate func loadCases() async throws {
        do {
            status = "Loading Cases"
            selectedCase   = nil
            selectedFolder = nil
            scrollToCaseID = nil
            scrollToFolderID = nil
            cases = try await Drive.shared.get(filesWithLabelID:Case.DriveLabel.Label.id.rawValue)
                                          .sorted(by: {$0.title.lowercased() < $1.title.lowercased()})
                                          .compactMap { Case($0)}
            
            categories = cases.compactMap { $0.label.category}
                              .unique()
                              .sorted(by: {$0.intValue < $1.intValue})
        } catch {
            throw error
        }
    }
    fileprivate func loadFolders(_ last: GTLRDrive_File) async throws {
        do {
            status = "Loading"
            folders = try await Drive.shared.getContents(of: last.id, onlyFolders: true)
            selectedFolder = stack.count > 1 ? last : nil
        } catch {
            throw error
        }
    }
    fileprivate func loadSpreadsheet() async throws {
        do {
            status = "Loading \(selectedCase?.title ?? "Spreadsheet")"
            try await selectedCase?.load(sheets: [.contacts, .contactData, .folders, .tags])
            try loadSuggestions()
        } catch {
            throw error
        }
    }
    fileprivate func loadSuggestions() throws {
        //dispatch used because suggestions is on @MainActor
        DispatchQueue.main.async {
            do {
//                print(#function)
                var limit = UserDefaults.standard.integer(forKey:BOF_Settings.Key.filingSuggestionLimit.rawValue)
                if limit <= 0 { limit = 5 }
                self.suggestions = try Suggestions.shared.sugguestFolders(for: self.items, rootLimit: limit)
                self.loadContactsAndTags()
                self.loadTasks()
            } catch {
                self.error = error
            }
        }
    }
    
    //LOAD FILE SPECIFIC
    func resetFilenames() {
        for item in items {
            item.resetFilename()
        }
    }
    @MainActor fileprivate func loadContactsAndTags() {
//        print(#function)

        guard let selectedCase else { print("No Selected Case");  return }
        
        
        suggestionData    = Suggestions.Data.merge(items.map(\.suggestionData))
        var searchNames   = suggestionData.contacts.lowercasedSet(key: \.name)
        var searchEmails  = suggestionData.contacts.lowercasedSet(key: \.email)
        let allEmailData  = Set(selectedCase.contactData.filter { $0.category.lowercased() == "email" })
        //searchData.contacts already extracted names/emails from searchData.words
        //That was done prior to selectedCase being loaded.  Now search for caseNames in selectedCase.contacts
       
        //Add Existing contacts
        var foundContact : Set<Case.Contact> = []
        var newData      : Set<Case.ContactData> = []
        
        for caseContact in selectedCase.contacts {
            let contactEmailData = allEmailData.lowercasedSet(filterKey: \.contactID, value: caseContact.id, key: \.value)
            //Email found in Case
            if contactEmailData.intersection(searchEmails).count > 0 {
                searchEmails.subtract(contactEmailData)
                foundContact.insert(caseContact)
            }
            //Contact Name found in SearchContact
            else if caseContact.name.lowerCasedWordsSet.intersection(searchNames).count > 0 {
                foundContact.insert(caseContact)
                searchNames.subtract(caseContact.name.lowerCasedWordsSet)
            }
        }
        
        //Add New Contacts
        for searchContact in suggestionData.contacts {
            if searchEmails.contains(searchContact.email) && searchNames.contains(searchContact.name.lowercased()) {
                    let newContact = Case.Contact(name: searchContact.name)
                    foundContact.insert(newContact)

                    let data    = Case.ContactData(id:UUID().uuidString, contactID: newContact.id, category: "email", label: "work", value: searchContact.email, note: nil)
                    newData.insert(data)
                    
                    searchEmails.remove(searchContact.email)
                    searchNames.remove(searchContact.name)
                }
       
        }
        //Sort
        filingContacts    = foundContact.sorted(by: {$0.name.ciCompare($1.name)})
        filingContactData = newData.sorted(by: {$0.value < $1.value})
        
        
        //Tags
        let mergedString = suggestionData.mergedString
        if UserDefaults.standard.bool(forKey: BOF_Settings.Key.filingSuggestionPartialTagMatch.rawValue) {
            filingTags = selectedCase.tags.filter({$0.name.hasWordIntersection(mergedString)})
        } else {
            filingTags = selectedCase.tags.filter({mergedString.ciContain($0.name) })
        }
        filingTags.sort(by: {$0.name.ciCompare($1.name)      })
      
//        print("\n******************************************************************************\n\n")
//        selectedCase.contacts.print(\.name, title:"All Contacts")
//        searchData.contacts.print(\.description, title:"Searching Contacts")
//        filingContacts.print( \.name, title:"Found Contacts")
//        
//        print("\n\nWords:")
//        searchData.words.print(\.self, title:"Search Words")
//        selectedCase.tags.print(\.name, title:"All Tags")
//        filingTags.print(\.name, title:"Tags")
//        print("\n******************************************************************************\n\n")

    }
    fileprivate func loadTasks() {
        filingTasks = []
    }
}

//MARK: - Selection
extension FileToCase_Delegate {
    func doubleClicked(_ aCase : Case) {
//        isLoading   = true
        let caseFolder = GTLRDrive_File()
        caseFolder.identifier = aCase.folderID
        caseFolder.name = aCase.title
        caseFolder.mimeType = GTLRDrive_File.MimeType.folder.rawValue
        stack.append(caseFolder)
    }
    func doubleClicked(_ folder:GTLRDrive_File) {
//        isLoading   = true
        stack.append(folder)
    }
    func select(_ folder:GTLRDrive_File) {
//        isLoading = true
        selectedDestination = folder
        Task { await load() }
    }
    func select(_ suggestion:FolderSuggestion, in aCase:Case) {
        byPassLoading = true
        selectedCase = aCase
        doubleClicked(aCase)

        if suggestion.root != nil {
            let folder = GTLRDrive_File()
            folder.name = suggestion.name
            folder.identifier = suggestion.id
            folder.mimeType = "application/vnd.google-apps.folder"
            doubleClicked(folder)
            selectedDestination = folder
        }
        byPassLoading = false
    }
    func pop(to folder:GTLRDrive_File?) {
        selectedDestination = nil
        if let folder, let index = stack.firstIndex(where : { $0.id == folder.id }){
            if index + 1 == stack.count {
                Task { await load() }
            } else {
                stack.removeSubrange(index+1..<stack.count)
            }
        } else {
            stack.removeAll()
        }
    }
}


//MARK: - Add
extension FileToCase_Delegate {
    //Case
    func addNewCase(_ newCase:Case) {
       cases.append(newCase)
       cases.sort(by: {$0.title.lowercased() < $1.title.lowercased()})
        categories = cases.compactMap { $0.label.category}
                          .unique()
                          .sorted(by: {$0.intValue < $1.intValue})
        
       selectedCase = newCase
       scrollToCaseID = newCase.id
        

    }
    
    //Folders
    func addNewFolder(_ name:String, parentID:String) async throws  {
        do {
            let newFolder = try await Drive.shared.create(folder: name, in:parentID)
            folders.append(newFolder)
            folders.sort { $0.title.ciCompare($1.title)}
            selectedFolder = newFolder
            scrollToFolderID = newFolder.id
        } catch {
            throw error
        }
    }
    
    //Contacts
    func contactIsInSpreadsheet(_ id:Case.Contact.ID) -> Bool {
        selectedCase?.contacts.first(where: {$0.id == id }) ?? nil != nil
    }
    func addFilingContact(_ contact:Case.Contact) {
        if !filingContacts.contains(where: {$0.id == contact.id }) {
            filingContacts.append(contact)
        } else {
            print("\n\n****Unable to add: \(contact.name) ID \(contact.id)")
            for filingContact in self.filingContacts {
                print("\t\(filingContact.id) \(filingContact.name)")
            }
        }
    }
    func addNewFilingContact(_ name:String) -> Case.Contact {
        if let existing = selectedCase?.contacts.first(where: {$0.name.lowercased() == name.lowercased()}) {
            addFilingContact(existing)
            return existing
        } else {
            let newContact = Case.Contact(name: name)
            addFilingContact(newContact)
            return newContact
        }
    }
    func removeFilingContact(_ id:Case.Contact.ID) {
        _ = filingContacts.remove(id:id)
        removeAllContactData(for:id)
    }
    
    //Contacts Data
    func contactDataIsInSpreadsheet(_ id:Case.ContactData.ID) -> Bool {
        selectedCase?.contactData.first(where: {$0.id == id }) ?? nil != nil
    }
    func addContactData(_ data:Case.ContactData) {
        //only add if not already in filing and does not already exist in case
        guard filingContactData.first(where: {$0.id == data.id}) == nil else { return }
        guard !contactDataIsInSpreadsheet(data.id) else { return }
        filingContactData.append(data)
    }
    func removeContactData(_ id:String) {
        _ = filingContactData.remove(id: id)
    }
    func removeAllContactData(for contactID:Case.Contact.ID) {
        filingContactData.removeAll(where: {$0.contactID == contactID})
    }
    
    //Tags
    func tagIsInSpreadsheet(_ id:Case.Tag.ID) -> Bool {
        selectedCase?.tags.first(where: {$0.id == id }) ?? nil != nil
    }
    func addTag(_ tag:Case.Tag) {
        if !filingTags.contains(where: {$0.id == tag.id }) {
            filingTags.append(tag)
        }
    }
    func addNewTag(_ text:String) -> Case.Tag {
        if let existing = selectedCase?.tags.first(where: {$0.name.lowercased() == text.lowercased()}) {
            addTag(existing)
            return existing
        } else {
            let newTag = Case.Tag(id: UUID().uuidString, name: text, note: nil)
            addTag(newTag)
            return newTag
        }
    }
    func removeTag(_ tagID:Case.Tag.ID) {
        filingTags.removeAll(where: {$0.id == tagID})
    }
}


//MARK: - Sheet Rows
fileprivate extension FileToCase_Delegate {
    var pathFolders        : [GTLRDrive_File] {
        guard let selectedCase, let selectedDestination else { return [] }
        
        let stackFolders = stack.filter { folder  in
            guard folder.id != selectedCase.folderID  else { return false }
            guard folder.id != selectedDestination.id else { return false }
            return true
        }
        return stackFolders + [selectedDestination]
    }
    var newFolderRows      : [Case.Folder] {
        guard let selectedCase else { return [] }
        let folderIDs = selectedCase.folders.map(\.folderID)
        return pathFolders.filter { !folderIDs.contains($0.id)}
                          .compactMap({ Case.Folder(file: $0)})
    }
    var newContactRows     : [Case.Contact] {
        filingContacts.filter { !contactIsInSpreadsheet($0.id)}
    }
    var newContactDataRows : [Case.ContactData] {
        filingContactData.filter { !contactDataIsInSpreadsheet($0.id)}
    }
    var newTagRows         : [Case.Tag] {
        filingTags.filter { !tagIsInSpreadsheet($0.id)}
    }
    var newFileRows        : [Case.File] {
        items.compactMap { item in
           Case.File(fileID: item.file.id,
                      name: item.file.titleWithoutExtension,
                      mimeType: item.file.mime.rawValue,
                      fileSize: item.file.fileSizeString,
                      folderIDs: pathFolders.map(\.id),
                      contactIDs: filingContacts.map(\.id),
                      tagIDs: filingTags.map(\.id),
                      idDateString: Date.idString)
        }
    }
    var newTaskRows        : [Case.Task] {
        for (index, _) in filingTasks.enumerated() {
            filingTasks[index].fileIDs = items.compactMap(\.file.id)
            filingTasks[index].contactIDs = filingContacts.map(\.id)
            filingTasks[index].tagIDs = filingTags.map(\.id)
        }
        return filingTasks
    }
    var newSheetRows       : [any SheetRow] {
        var sheetRows : [any SheetRow] = []
        sheetRows += newFolderRows
        sheetRows += newContactRows
        sheetRows += newContactDataRows
        sheetRows += newTagRows
        sheetRows += newFileRows
        sheetRows += newTaskRows
        return sheetRows
    }
}


//MARK: - Add to Case Workflow
extension FileToCase_Delegate {
    func fileLater(_ destinationID:String) async -> [FileToCase_Item]? {
        do throws (Filing_Error){
            isLoading = true
            isFiling  = true
            progress  = 0.0
            try await uploadLocalItemsTo(destinationID)
            progress  = 0.0
            isLoading = false
            isFiling  = false
            return items.filter { $0.file.parents?.first == destinationID }
        } catch {
            isFiling  = false
            isLoading = false
            self.error = error
            return nil
        }
    }
    func addToCase() async -> [FileToCase_Item]? {
        guard canAddToCase else { return nil }
        do throws (Filing_Error){
            guard let selectedDestination else { throw .destinationNotSelected }
            isLoading = true
            isFiling  = true
            progress  = 0.0
            try await moveFiles()
            try await updateSpreadsheet()
            try await updateSuggestions()
        
            successfullyAddedToCase()
            progress  = 0.0
            isLoading = false
            isFiling  = false
            return items.filter { $0.file.parents?.first == selectedDestination.id }
        } catch {
            isFiling  = false
            isLoading = false
            self.error = error
            return nil
        }
    }
    func moveFiles() async throws(Filing_Error) {
        do throws(Filing_Error) {
            guard let selectedDestination else { throw .destinationNotSelected }
            try await moveFromFilingDriveToDestination()
            try await uploadLocalItemsTo(selectedDestination.id)
        } catch {
            throw error
        }
    }
    func moveFromFilingDriveToDestination() async throws(Filing_Error) {
        do throws(Filing_Error) {
            guard let selectedDestination else { throw .destinationNotSelected }
            let filesToMove = items.compactMap({$0.file})
            if filesToMove.count > 0 {
                status = "Moving Files..."
                let tuples : [(fileID:String, parentID:String, destinationID:String)] = filesToMove.compactMap { file in
                    if file.parents?.first != selectedDestination.id {
                        return (fileID:file.id, parentID:file.parents?.first ?? "", destinationID:selectedDestination.id)
                    }
                    return nil //file already moved, this could be a retry
                }
                do {
                    let result = try await Drive.shared.move(tuples: tuples)
                    for success in result.successes ?? [:] {
                        if let uploadedFile = success.value as? GTLRDrive_File,
                           let item = items.first(where: {$0.file.id == uploadedFile.id}) {
                            item.file.parents = uploadedFile.parents
                            item.file.name    = uploadedFile.name
                            print("Updated: \(item.filename)")
                        }
                    }
                } catch  {
                    throw Filing_Error.filesNotMoved(error.localizedDescription)
                }
            }
        } catch {
            throw error
        }
    }
    func uploadLocalItemsTo(_ destinationID:String) async throws(Filing_Error) {
        //this can be called when adding to a case
        //or when user wants to upload a local file to Filing Drive
        do throws(Filing_Error) {
//            let filesToUpload = self.items.filter { $0.file == nil && $0.localURL != nil }
//            if items.count > 0 {
//                for item in items {
//                    status = "Uploading \(item.filename)"
//                    let appProp = item.pdfGmailThread?.driveAppProperties
//                    do {
//                        let uploadedFile =  try await Drive.shared.upload(url:item.localURL!, filename:item.filename, to:destinationID, appProperties:appProp) { progress in
//                            self.progress = progress
//                        }
//                        if let index = items.firstIndex(of: item) {
//                            items[index].file = uploadedFile
//                        }
//                    } catch {
//                        throw .uploadFailed(item.filename, error.localizedDescription)
//                    }
//                }
//                if progress < 1 { progress = 1.0}
//            }
        } catch {
            throw error
        }
    }
    func updateSpreadsheet() async throws(Filing_Error) {
        do throws(Filing_Error)   {
            guard let selectedCase else { throw .caseNotSelected }
            do {
                status = "Updating \(selectedCase.title)..."
                let newSheetRows = newSheetRows
                
                //update Google Sheet
                try await Sheets.shared.append(newSheetRows, to:selectedCase.id)
                
                //Update loaded case already in memory
                for newSheetRow in newSheetRows {
                    if let contactRow = newSheetRow as? Case.Contact {
                        selectedCase.contacts.append(contactRow)
                    } else if let contactDataRow = newSheetRow as? Case.ContactData {
                        selectedCase.contactData.append(contactDataRow)
                    } else if let file = newSheetRow as? Case.File {
                        selectedCase.files.append(file)
                    } else if let tag  = newSheetRow as? Case.Tag {
                        selectedCase.tags.append(tag)
                    }
                    else if let task  = newSheetRow as? Case.Task {
                        selectedCase.tasks.append(task)
                   }else {
                       print("\(#function) Not setup to process: \(newSheetRow)")
                    }
                }
           
            } catch  {
                throw Filing_Error.filesMovedButSpreadsheetNotUpdated(error.localizedDescription)
            }
        } catch {
            throw error
        }
    }
    func retryUpdateSpreadsheet() async throws(Filing_Error) {
        guard let selectedCase else { throw .caseNotSelected }
        do {
            self.error = nil
            isLoading = true
            isFiling  = true
            //retry
            try await Sheets.shared.append(newSheetRows, to:selectedCase.id)
            try await updateSuggestions()
            successfullyAddedToCase()
            isLoading = false
            isFiling  = false
        } catch {
            selectedCase.label.audit = .yes
            _ = try? await Drive.shared.label(modify: Case.DriveLabel.Label.id.rawValue, modifications:[selectedCase.label.labelModification], on:selectedCase.id)
            isLoading = false
            isFiling  = false
            self.error = error
        }
    }
    func updateSuggestions() async throws(Filing_Error) {
        do throws(Filing_Error) {
            guard let selectedDestination else { throw .destinationNotSelected }
            guard let selectedCase else { throw .caseNotSelected }
            status = "Filed!"
            do {
                try await Suggestions.shared.update(newSheetRows, to : [selectedDestination], root: selectedCase.file)
            } catch {
                throw Filing_Error.suggestionsNotUpdated(error.localizedDescription)
            }

        } catch {
            throw error
        }
    }
    func successfullyAddedToCase() {
        justFiled = items
        items.removeAll()
        selectedDestination = nil
        stack.removeAll()
        selectedCase = nil
    }
}
