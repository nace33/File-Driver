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
    struct SearchData {
        let words      : Set<String>
        let strings    : Set<String>
        let contacts   : Set<PDFGmailThread.Person>
        
        //created in
        ///Suggesstions.getSearchData(for files:[GTLRDrive_File]) -> SearchData
    }
}

extension Suggestions.SearchData {
    var mergedString : String { strings.joined(separator:" ")}
}
