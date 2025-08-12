//
//  SD_Suggestions.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/25/25.
//

import SwiftUI
import SwiftData
import BOF_SecretSauce

/*
    FilerCase           FilerSearchString
        ^                       ^
        ^                       ^
        ----->>FilerFolder<<-----
*/


//MARK: - Case
@Model final class FilerCase {
    var spreadsheetID   : String = ""
    var name            : String = ""
    var lastUsed        : Date   = Date()
    var timesUsed       : Int    = 0
    @Relationship(deleteRule: .cascade, inverse: \FilerFolder.aCase)  var folders  : [FilerFolder]?  = []

    private init(_ aCase:Case) {
        self.spreadsheetID   = aCase.id
        self.name            = aCase.title
        self.lastUsed        = Date()
        self.timesUsed       = 1
    }
    
    //Build from scrach
    //Fetch
    @MainActor static func fetch(spreadsheetID:String) -> FilerCase? {
        var descriptor = FetchDescriptor<FilerCase>()
        descriptor.predicate = #Predicate { aCase in
            aCase.spreadsheetID == spreadsheetID
        }
        return BOF_SwiftData.shared.fetch(descriptor)?.first
    }

    @MainActor static func rebuild(_ aCase:Case) -> FilerCase {
        //Create Case
        let newCase = FilerCase(aCase)
      
        //Get or Create Folders
        ///This will not rebuild the path for each folder because the parent ID is not saved in the Google SHeet (because it can change in google drive and create a sync issue).
        newCase.folders = FilerFolder.get(caseFolders: aCase.folders, update: false)
        
        //Create Search Strings
        ///contacts, emails and tags creataed together because they are tracked by an itemID.
        let searchStrings : [FilerSearchString] = get(contacts: aCase.contacts, data: aCase.contactData, tags: aCase.tags, update: false)
        
        //Files
        let filenameSearchStrings = get(files: aCase.files, update: false)
        
        //Relationships
        for folder in newCase.folders ?? [] {
            let allFiles = aCase.files.filter { $0.folderID == folder.folderID }
                                      .sorted(by: {$0.idDateString > $1.idDateString})
            folder.timesUsed = allFiles.count
            if let idDateString = allFiles.first?.idDateString {
                folder.lastUsed  =  Date.idDate(idDateString) ?? Date()
            }
            
            //Apply relationship for filenames
            var fileWords : Set<String> = []
            for file in allFiles{
                fileWords.formUnion(file.filerSearchStringWords)
            }
            folder.searchStrings?.append(contentsOf: filenameSearchStrings.filter({fileWords.contains($0.text) }))
            
            //Apply relationships for tags, names, and emails
            var matchingIDs : Set<String> = []
            matchingIDs.formUnion(allFiles.compactMap(\.contactIDs).flatMap(\.self))
            matchingIDs.formUnion(allFiles.compactMap(\.tagIDs).flatMap(\.self))
            folder.searchStrings?.append(contentsOf: searchStrings.filter { matchingIDs.contains($0.itemID)})
          
        }
        return newCase
    }
    @MainActor func append(folders:[Case.Folder], contacts:[Case.Contact], data:[Case.ContactData], files:[Case.File], tags:[Case.Tag] , save:Bool) {
        //major different between append and rebuild, is append presumes all files are in all folders
        //whereas Rebuild the files do not below to all folders
        let filerFolders = FilerFolder.get(caseFolders:folders, update: true)
        
        //Contacts, data, tags
        let searchStrings = FilerCase.get(contacts: contacts, data: data, tags: tags, update: true)
       
        //Files
        let filenameSearchStrings = FilerCase.get(files:files, update: true)
        
        //Relationships
        for filerFolder in filerFolders {
            filerFolder.searchStrings?.append(contentsOf: searchStrings)
            filerFolder.searchStrings?.append(contentsOf: filenameSearchStrings)
        }
        
        self.folders?.append(contentsOf: filerFolders)
        if save {
            try? BOF_SwiftData.shared.container.mainContext.save()
        }
    }
    
    
    //GET
    @MainActor static func get(_ aCase:Case) -> FilerCase {
        if let filerCase = fetch(spreadsheetID: aCase.id) {
            filerCase.lastUsed = Date()
            filerCase.timesUsed += 1
            return filerCase
        } else {
            let newFilerCase = FilerCase(aCase)
            BOF_SwiftData.shared.container.mainContext.insert(newFilerCase)
            return newFilerCase
        }
    }
    @MainActor fileprivate static func get(contacts:[Case.Contact], data:[Case.ContactData], tags:[Case.Tag], update:Bool) -> [FilerSearchString] {
        var searchStrings : [FilerSearchString] = []
        ///Contacts
        for caseContact in contacts {
            searchStrings.append(contentsOf: FilerSearchString.get(itemID: caseContact.id, text: caseContact.name, category: .name, update: update))
        }
        ///Emails
        for caseEmail in data.filter({$0.category == "email"}) {
            searchStrings.append(contentsOf: FilerSearchString.get(itemID: caseEmail.contactID, text: caseEmail.value, category: .email, update: update))
        }
        //Tags
        for caseTag in tags {
            searchStrings.append(contentsOf: FilerSearchString.get(itemID: caseTag.id, text: caseTag.name, category: .tag, update: update))
        }
        return searchStrings
    }
    ///Case.Files are treated differently from Case.Contact,ContactData and Case.Tag because there is no relevant itemID.
    @MainActor fileprivate static func get(files:[Case.File], update:Bool) -> [FilerSearchString] {
        var fileWords : Set<String> = []
        for file in files {
            fileWords.formUnion(file.filerSearchStringWords)
        }
        var filenameSearchStrings : [FilerSearchString] = []
        for fileWord in fileWords {
            filenameSearchStrings.append(contentsOf: FilerSearchString.get(itemID:UUID().uuidString, text: fileWord, category:.filename, update: update))
        }
        return filenameSearchStrings
    }
}


//MARK: - Foer
@Model final class FilerFolder {
    var folderID  : String = ""
    var name      : String = ""
    var lastUsed  : Date   = Date()
    var timesUsed : Int    = 0
    
    //Relationships
    var aCase     : FilerCase?
    @Relationship(deleteRule: .nullify, inverse: \FilerSearchString.folders)
    var searchStrings  : [FilerSearchString]?  = []

    
    init(folder: Case.Folder) {
        self.name       = folder.name
        self.folderID   = folder.id
        self.lastUsed   = Date()
        self.timesUsed  = 1
    }
    @MainActor static func fetch(folderID:String) -> FilerFolder? {
        var descriptor = FetchDescriptor<FilerFolder>()
        descriptor.predicate = #Predicate { folder in
            folder.folderID == folderID
        }
        return BOF_SwiftData.shared.fetch(descriptor)?.first
    }
    @MainActor static func get(caseFolders:[Case.Folder], update:Bool) -> [FilerFolder] {
        var filerFolders = [FilerFolder]()
        for caseFolder in caseFolders {
            if let filerFolder = FilerFolder.fetch(folderID: caseFolder.folderID) {
                if update {
                    filerFolder.lastUsed  = Date()
                    filerFolder.timesUsed += 1
                }
                filerFolders.append(filerFolder)
            } else {
                let newFilerFolder = FilerFolder(folder: caseFolder)
                filerFolders.append(newFilerFolder)
            }
        }
        return filerFolders.unique(key: \.folderID)
    }
}


//MARK: - SearchString
@Model final class FilerSearchString {
    #Index<FilerSearchString>( [\.text], [\.itemID])
    
    var itemID    : String          = ""
    var text      : String          = ""
    var lastUsed  : Date            = Date()
    var timesUsed : Int             = 0
    var intValue  : Int             = 0
    var folders   : [FilerFolder]? = []
    var category  : Category { .init(intValue)   }
    enum Category : Int, CaseIterable {
        case unknown, filename, name, email, tag
        var title : String {
            switch self {
            case .unknown:
                "Unknown"
            case .name:
                "Names"
            case .email:
                "Emails"
            case .tag:
                "Tags"
            case .filename:
                "Words"
            }
        }
        var breakDownTextIntoWords : Bool {
            switch self {
            case .filename, .name:
                true
            default:
                false
            }
        }
        init(_ intValue:Int) {
            if intValue == Category.filename.rawValue {
                self = .filename
            }
            else if intValue == Category.name.rawValue {
                self = .name
            }
            else if intValue == Category.email.rawValue {
                self = .email
            }
            else if intValue == Category.tag.rawValue {
                self = .tag
            }  else {
                self = .unknown
            }
        }
    }
    
    private init(itemID: String, text: String, category: FilerSearchString.Category) {
        self.itemID     = itemID
        self.text       = text
        self.lastUsed   = Date()
        self.timesUsed  = 1
        self.intValue   = category.rawValue
    }


    @MainActor static func fetch(_ itemID:String, text:String, category:FilerSearchString.Category) -> FilerSearchString? {
        var descriptor = FetchDescriptor<FilerSearchString>()
        let intValue = category.rawValue
        switch category {
        case .filename:
            descriptor.predicate = #Predicate { searchString in
                searchString.text == text && searchString.intValue == intValue
            }
        default:
            descriptor.predicate = #Predicate { searchString in
                searchString.itemID == itemID && searchString.text == text && searchString.intValue == intValue
            }
        }
        return BOF_SwiftData.shared.fetch(descriptor)?.first
    }
    @MainActor static func search(strings:Set<String>, category:FilerSearchString.Category?) -> [FilerSearchString]? {
        var descriptor = FetchDescriptor<FilerSearchString>()
        let stringsToSearch = strings.lowercasedSet()

        if let intValue = category?.rawValue {
            descriptor.predicate = #Predicate { searchString in
                stringsToSearch.contains(searchString.text) && searchString.intValue == intValue
            }
        } else {
            descriptor.predicate = #Predicate { searchString in
                stringsToSearch.contains(searchString.text)
            }
        }
        return BOF_SwiftData.shared.fetch(descriptor)

    }
    @MainActor static func get(itemID:String, text:String, category:FilerSearchString.Category, update:Bool) -> [FilerSearchString] {
        var searchStrings = [FilerSearchString]()
        
   
        let strings : Set<String>
        switch category {
        case .unknown:
            strings = []
        case .name:
            strings =  text.lowerCasedWordsSet
        case .email:
            strings = [text.lowercased()]
        case .tag:
            strings = [text.lowercased()]
        case .filename:
            strings =  text.lowerCasedWordsSet
        }
   
        for str in strings {
            guard str.count > 0 else { continue }
            if let existingSearchString = fetch(itemID, text: str, category: category) {
                if update {
                    existingSearchString.lastUsed  = Date()
                    existingSearchString.timesUsed += 1
                }
                searchStrings.append(existingSearchString)
            } else {
                searchStrings.append(.init(itemID: itemID, text: str, category: category))
            }
        }
   
        return searchStrings
    }

}



//MARK: - Case File Extension
fileprivate extension Case.File {
    var filerSearchStringWords: Set<String> {
        let sanitizedFilename = Self.sanitize(filename:filename)
        let sanitizedWords    = sanitizedFilename.lowerCasedWords
                                                 .compactMap({Self.sanitize(filename: $0)})
        return Set(sanitizedWords)
    }
    static func sanitize(filename:String) -> String {
        filename.remove(parts: [.dates, .pathExtension, .wordsBelowCharacterCount(5), .extraWhitespaces,],
                    tags: [.adjective, .adverb, .conjunction, .pronoun, .determiner, .preposition])
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: ":", with: "")
            .lowercased()
    }
}
