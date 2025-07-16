//
//  Suggestions.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/30/25.
//

import SwiftUI
import SwiftData
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce
///translates the Case spreadsheet and its rows into Swift Data
///purpose is to generate filing suggestions

@Observable
@MainActor
final class Suggestions {
    static let shared: Suggestions = { Suggestions() }() //Singleton
    var context : ModelContext { BOF_SwiftData.shared.container.mainContext}
    
    //This should match what is SwiftData
    //Cached for efficiency sake due to large volume of fetched requests that can occur (i.e. rebuild case spreadsheet)
    fileprivate var _blockedWords: Set<String> = []
    var blockedWords : Set<String> {
        get {
            if _blockedWords.isEmpty {
                _blockedWords = BOF_SwiftData.shared.getBlockedWords()
            }
            return _blockedWords
        } set {
            _blockedWords = newValue
        }
    }
}

//MARK: Suggestions
extension Suggestions {
    func sugguestFolders(for items:[FileToCase_Item], rootLimit:Int? = nil) throws -> [FolderSuggestion] {
        guard items.count > 0 else { return []}
        let searchData   = Suggestions.Data.merge(items.map(\.suggestionData))
        let searchWords  = searchData.words
        let searchEmails = searchData.contacts.map { $0.email.lowercased() }
        let allWords     = Set(searchWords + searchEmails).subtracting(blockedWords)
        
        let folders = try fetchFolders(containing: allWords)
        if let rootLimit, rootLimit > 0, folders.count > rootLimit {
            var roots : [FolderSuggestion] = []
            return folders.filter { folder in
                guard let root = folder.root  else { return false }
                guard roots.count < rootLimit else { return roots.contains(root) }
                roots.append(root)
                return true
            }
        } else {
            return folders
        }
    }
    fileprivate func suggestWords(from sheetRows:[any SheetRow]) -> Set<String> {
        guard sheetRows.count > 0 else { return [] }
        var words : Set<String> = []
        
        for row in sheetRows {
            if let contactRow = row as? Case.Contact {
                words.formUnion(contactRow.name.lowerCasedWordsSet)
            } else if let contactDataRow = row as? Case.ContactData {
                words.insert(contactDataRow.value.lowercased())
            } else if let file = row as? Case.File {
                if let sanitized = sanitize(file.filename) {
                    words.formUnion(sanitized.lowerCasedWordsSet)
                }
            } else if let tag  = row as? Case.Tag {
                words.insert(tag.name)
            } else {
                print("Not setup to process: \(row)")
            }
        }
        return words.subtracting(blockedWords)
    }
    fileprivate func suggestWords(for caseSpreadsheet:Case, folderID:String?) -> Set<String> {
        let files : [Case.File]
        if let folderID {
            files = caseSpreadsheet.files.filter { $0.folderIDs.contains(folderID)}
        } else {
            files = caseSpreadsheet.files
        }
        var sheetRows : [any SheetRow] = []
        for file in files {
            sheetRows.append(file)
            if file.contactIDs.count > 0 {
                sheetRows.append(contentsOf: caseSpreadsheet.contacts(with: file.contactIDs))
                sheetRows.append(contentsOf:caseSpreadsheet.contactData(with: file.contactIDs, category: "email"))
            }
            
            if file.tagIDs.count > 0 {
                sheetRows.append(contentsOf: caseSpreadsheet.tags(with: file.tagIDs))
            }
        }
        return suggestWords(from: sheetRows)
    }
}


//MARK: Update
extension Suggestions {
    func update(_ caseSpreadsheet:Case, save:Bool) async throws -> FolderSuggestion {
        ///this is called when importing an entire case spreadsheet (i.e.an import or rebuild)
        do {
            //Load spreadsheet
            try await caseSpreadsheet.load(sheets: [.contacts, .contactData, .folders, .tags, .files])
            //setup root
            let root    = try createRoot(caseSpreadsheet.file)
            root.words?.removeAll()
            root.children?.removeAll()

            //Create words
            ///takes about 0.15 seconds
//            let start = CFAbsoluteTimeGetCurrent()
            //Option 1 is to get all words and create swift data models up front
            //Option 2 is to only get words for each folder, create/get swift data words at that time
            //Option 2 is testing about 0.01 faster on small data sets
            
            //Option 1 is commented out
//            let uniqueWords    = getSearchWords(for: caseSpreadsheet, folderID: nil)
            
            //Create swift data models
//            let words          = try createWords(uniqueWords, sanitize:false)//already sanitized
            
            //Create folders
            let driveFolders   = caseSpreadsheet.driveFolders
            let folders        = try createFolders(driveFolders, root: root)
            
            //Attach relationships & set metadata
            for folder in folders {
                //relationships
                ///This redoes work already done above in order to figure out which words belong to each folder
                let folderWords = suggestWords(for:caseSpreadsheet, folderID: folder.id)
                folder.words    = try createWords(folderWords, sanitize: false)
//                folder.words    = words.filter { folderWords.contains($0.text)}
                
                //meta-data
                //Last used == file with most recent id (which is a UUID().uuidString)
                //times used == number of times a file was sent here
                let files = caseSpreadsheet.files.filter { $0.folderIDs.contains(folder.id)}
                folder.timesUsed = files.count
                
                if let maxDateIDString = files.max(by: {$0.idDateString > $1.idDateString})?.idDateString {
                    if let date = Date.idDate(maxDateIDString) {
                        folder.lastUsed = date
                    }
                }
            }
//            let diff = CFAbsoluteTimeGetCurrent() - start
//            print("Loading Words Took: \(diff) seconds")
            if save {
                try context.save()
            }
            
            return root
        } catch {
            throw error
        }
    }
    func update(_ sheetRows:[any SheetRow], to folders:[GTLRDrive_File], root:GTLRDrive_File) throws {
        ///Called from AddToCase and Suggestions.add(case, save)
        let suggestedWords = suggestWords(from: sheetRows)
        let root           = try createRoot(root)
        let folders        = try createFolders(folders, root: root)
        let words          = try createWords(suggestedWords, sanitize: false)
        
        let newDate = Date()
        for word in words {
            word.folders?.append(contentsOf: folders)
            word.lastUsed = newDate
            word.lastUsed += 1
        }
        for folder in folders {
            folder.lastUsed = newDate
            folder.timesUsed += 1
        }
        root.lastUsed = newDate
        root.timesUsed += 1
        
        try context.save()
    }
}


//MARK: Create
extension Suggestions {
    fileprivate func createRoot(_ rootFolder:GTLRDrive_File) throws -> FolderSuggestion {
        do {
            if let root = try get(rootFolder) {
                return root
            } else {
                let name = Case.DriveLabel(file: rootFolder)?.title ?? rootFolder.title
                let root = FolderSuggestion(rootFolder.id, name:name)
                context.insert(root)
                return root
            }
        } catch {
            throw error
        }
    }
    fileprivate func createWords(_ words:Set<String>, sanitize:Bool) throws -> [WordSuggestion] {
        do {
            //convert to lowercased - only thing that is stored / compared
            let sanitizedWords : Set<String>
            if sanitize {
                sanitizedWords  = self.sanitize(words)
            } else {
                sanitizedWords = words
            }
            guard sanitizedWords.count > 0 else { return [] }
            //Get existing
            var words           = try get(sanitizedWords)
            
            //Add New words
            let foundWords      = words.compactMap(\.text)
            let notFoundWords   = sanitizedWords.filter { !foundWords.contains($0)}
            
            //Create New words and insert into context
            let newWords        = notFoundWords.compactMap { WordSuggestion($0, isBlocked: false)}
            for newWord in newWords {
                context.insert(newWord)
            }
            
            //merge words
            words += newWords
            
            return words
        } catch {
            throw error
        }
    }
    fileprivate func createFolders(_ driveFolders:[GTLRDrive_File], root:FolderSuggestion) throws -> [FolderSuggestion] {
        do {
            //Get existing
            var folders         = try get(driveFolders)
            
            //Add New words
            let foundFolders    = folders.compactMap(\.id)
            let notFoundFolders = driveFolders.filter { !foundFolders.contains($0.id)}
            
            //Create new Folders & Insert into context
            let newFolders      = notFoundFolders.compactMap { FolderSuggestion($0.id, name: $0.title)}
            for folder in newFolders {
                context.insert(folder)
            }
            
            //merge folders
            folders += newFolders
            
            //Add root to parent
            root.children?.append(contentsOf: folders)
            
            return folders
        } catch {
            throw error
        }
    }
}


//MARK: Delete
extension Suggestions {
    func deleteAllSuggestions() throws {
        do {
            try context.delete(model:WordSuggestion.self)
            try context.delete(model:FolderSuggestion.self)
            try context.save()
        } catch {
            print(#function + " \(error.localizedDescription)")
            throw error
        }
    }
    func clearRelationships(_ folder:FolderSuggestion) throws {
        do {
            folder.isSyncing = true
            folder.children?.removeAll()
            folder.words?.removeAll()
            try context.save()
            folder.isSyncing = false
        } catch {
            folder.isSyncing = false
            throw error
        }
    }
}

//MARK: Sanitize
fileprivate extension Suggestions {
    //Sanitization has to occur at string level for dates, etc to be recognized
    func sanitize(_ text:String) -> String? {
        let str = text.remove(parts: [.dates, .pathExtension, .wordsBelowCharacterCount(3), .extraWhitespaces],
                              tags: [.adjective, .adverb, .conjunction, .pronoun, .determiner, .preposition])
                      .lowercased()
        return str.count > 0 ? str : nil
    }
    func sanitize(_ words:Set<String>) -> Set<String> {
        var sanitizedWords : Set<String> = []
        for word in words.subtracting(blockedWords) {
            if let sanitized = sanitize(word) {
                sanitizedWords.insert(sanitized)
            }
        }
        return sanitizedWords
    }
}


//MARK: Fetch
fileprivate extension Suggestions {
    func fetch<T:PersistentModel>(_ predicate:Predicate<T>?) throws -> [T] {
        do {
            var fetchDescriptor = FetchDescriptor<T>()
            fetchDescriptor.predicate = predicate
            return try context.fetch(fetchDescriptor)
        } catch {
            print("Failed to load fetch. \(error.localizedDescription)")
            throw error
        }
    }
    func fetchFolders(containing words:Set<String>) throws -> [FolderSuggestion] {
        do {
            let predicate       : Predicate<FolderSuggestion> = #Predicate { folder in
                folder.words?.contains {
                    words.contains($0.text)
                } == true
            }
            let folders = try fetch(predicate)
            let textHit  = 1
            let emailHit = 5
            
            return folders.sorted { lhs, rhs in
                var lhsCount  = 0
                if let leftWords = lhs.words {
                    for word in leftWords {
                        if words.contains(word.text) {
                            lhsCount += word.text.isValidEmail ? emailHit : textHit
                        }
                    }
                }
                var rhsCount = 0
                if let rhsWords = rhs.words {
                    for word in rhsWords {
                        if words.contains(word.text) {
                            rhsCount += word.text.isValidEmail ? emailHit : textHit
                        }
                    }
                }
 
                if lhsCount == rhsCount {
                    return lhs.lastUsed < rhs.lastUsed
                }
                return lhsCount > rhsCount
            }
        } catch {
            throw error
        }
    }
    func get(_ rootFolder:GTLRDrive_File) throws -> FolderSuggestion? {
        do {
            let searchID        = rootFolder.id
            let predicate       : Predicate<FolderSuggestion> = #Predicate { $0.parent == nil && searchID == $0.id }
            return try fetch(predicate).first
        } catch {
            throw error
        }
    }
    func get(_ driveFolders:[GTLRDrive_File]) throws -> [FolderSuggestion] {
        do {
            //Get existing
            let folderIDs       = driveFolders.compactMap(\.id)
            let predicate       : Predicate<FolderSuggestion> = #Predicate { folderIDs.contains($0.id)}
            return try fetch(predicate)
        } catch {
            throw error
        }
    }
    func get(_ words:Set<String>) throws -> [WordSuggestion] {
        do {
            //Get existing
            let predicate : Predicate<WordSuggestion> = #Predicate { $0.isBlocked == false && words.contains($0.text)}
            return try fetch(predicate)
        } catch {
            throw error
        }
    }
    func get(_ word:String) throws -> WordSuggestion? {
        do {
            //Get existing
            let predicate : Predicate<WordSuggestion> = #Predicate { word == $0.text}
            return try fetch(predicate).first
        } catch {
            throw error
        }
    }
}


//MARK: Block
extension Suggestions {
    func resyncBlockedWords() -> Set<String> {
        _blockedWords.removeAll()
        return self.blockedWords
    }
    func block(_ text:String) throws {
        let words = try createWords([text], sanitize: true)
        for word in words {
            word.isBlocked = true
        }
        blockedWords.formUnion(words.compactMap({$0.text}))
    }
    func toggleBlock(_ word:WordSuggestion) {
        word.isBlocked.toggle()
        if word.isBlocked {
            blockedWords.insert(word.text)
        } else {
            blockedWords.remove(word.text)
        }
    }
}
