//
//  FilingSuggestion.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/27/25.
//

import Foundation

struct FilingSuggestion : Identifiable {
    var id           : String { caseID }
    //Select Case
    let caseID       : String
    let folderID     : String
    //Location in Case
    let subFolderIDs : [String]
    //MetaData for Filing Row
    let contactIDs   : [String]//first id is considered From
    let tags         : [String]

    let destinationID : String?
}
