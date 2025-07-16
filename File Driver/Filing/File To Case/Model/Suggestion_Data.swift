//
//  SuggestionData.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/6/25.
//

import Foundation
import BOF_SecretSauce

//MARK: Get Search Data
extension Suggestions {
    struct Data {
        let words      : Set<String>
        let strings    : Set<String>
        let contacts   : Set<EmailThread.Person>
        
        //created in
        ///Suggesstions.getSearchData(for files:[GTLRDrive_File]) -> SearchData
    }
    
    
}

extension Suggestions.Data {
    var mergedString : String { strings.joined(separator:" ")}
    
    static func merge(_ data:[Suggestions.Data]) -> Suggestions.Data {
        var contacts         : Set<EmailThread.Person> = []
        var searchWords      : Set<String> = []
        var searchStrings    : Set<String> = []
        for d in data {
            searchWords.formUnion(d.words)
            searchStrings.formUnion(d.strings)
            contacts.formUnion(d.contacts)
        }
        return Suggestions.Data(words:searchWords, strings:searchStrings, contacts:contacts)
    }
    static func sanitize(_ text:String) -> String? {
        let str = text.remove(parts: [.dates, /*.pathExtension,*/ .wordsBelowCharacterCount(3), .extraWhitespaces],
                              tags: [.adjective, .adverb, .conjunction, .pronoun, .determiner, .preposition])
                      .lowercased()
        return str.count > 0 ? str : nil
    }
}

extension Suggestions.Data {
    init(_ item:FileToCase_Item) {
        var contacts         : Set<EmailThread.Person> = []
        var searchWords      : Set<String> = []
        var searchStrings    : Set<String> = []
        
        //filename
        if let filename = Self.sanitize(item.file.titleWithoutExtension) {
            searchStrings.insert(filename)
            searchWords.formUnion(filename.lowerCasedWordsSet)
        }
        //Description property
        if let desc = item.file.descriptionProperty,
           let sanitized = Self.sanitize(desc)  {
            searchStrings.insert(desc)
            searchWords.formUnion(sanitized.lowerCasedWordsSet)
        }
  
        
        if let thread = EmailThread(appProperties: item.file.appProperties) {
            for contact in thread.uniquePeople(in: thread.fullHeaders, addMostLikelyName: true){
                contacts.insert(contact)
            }
            if let subject = Self.sanitize(thread.subject) {
                searchWords.formUnion(subject.lowerCasedWordsSet)
            }
        }
        
        //turn emails and names found in Words into Contacts
        //Note that this occurs BEFORE caseSpreadsheet is loaded, so only names found in appProperties contacts is performed
        let emailsInWords = Set(searchWords.filter { $0.isValidEmail })
        searchWords.subtract(emailsInWords)
        
        
        let emailContacts : [EmailThread.Person] = emailsInWords.compactMap { email in
            guard !contacts.map(\.email).cicContains(string: email) else { return nil }
            return .init(key: email, value: email)
        }
        contacts.formUnion(emailContacts)
        
        //remove names found in words that exist in contacts
        //typically this would be email host names that are found in filenames
        let lowerCasedString = contacts.map(\.lowercasedString).joined()
        let allWords = searchWords.filter {  !lowerCasedString.ciContain($0)  }

        self = Suggestions.Data(words:allWords, strings: searchStrings, contacts: contacts)
    }
}
