//
//  Suggestion_Models.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/30/25.
//

import SwiftUI
import SwiftData


//MARK: - Words
///Used for filtering and folder finding
@Model final class WordSuggestion {
    #Index<WordSuggestion>([\.text])
    var text        : String = ""
    var lastUsed    : Date   = Date()
    var timesUsed   : Int    = 0
    var isBlocked   : Bool   = false
    @Relationship(deleteRule: .nullify, inverse: \FolderSuggestion.words) var folders  : [FolderSuggestion]? = []
    init(_ text: String, isBlocked:Bool) {
        self.text = text
        self.isBlocked = isBlocked

    }
}



//MARK: - Folder
///Stores reference to a folder user has 'Filed' to
@Model final class FolderSuggestion {
    var id          : String = ""
    var name        : String = ""
    var lastUsed    : Date   = Date()
    var timesUsed   : Int    = 0

    @Relationship var words    : [WordSuggestion]?   = []
    @Relationship var parent   : FolderSuggestion?   = nil
    @Relationship(deleteRule: .cascade, inverse: \FolderSuggestion.parent) var children : [FolderSuggestion]? = nil 

    init(_ id:String, name:String, parent:FolderSuggestion? = nil) {
        self.id = id
        self.name = name
        self.parent = parent
    }
    
    //local variable
    @Attribute(.ephemeral) var isSyncing = false
    
    //Computed Properties
    var path       : [String] {
        var path : [String] = []
        path.append(name)
        var parent = self.parent
        while parent != nil {
            if let parent {
                path.append(parent.name)
            }
            parent = parent?.parent
        }
        return path
    }
    var pathString : String {
        path.reversed().joined(separator: "/")
    }
    var root       : FolderSuggestion? {
        var parent = self.parent
        while parent != nil {
            if let nextParent = parent?.parent {
                parent = nextParent
            } else {
                return parent
            }
        }
        return nil
    }
}

