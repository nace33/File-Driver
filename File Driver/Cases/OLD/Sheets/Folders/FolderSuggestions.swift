//
//  FolderSuggestions.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/16/25.
//

import Foundation

//MARK: Suggestions
extension Case_OLD.Folder {
    enum Suggestion : String, CaseIterable {
        case authorizations, billing, discovery, docket, evidence, research, settlement, trial, workProduct
        //Authorizations
        case medical, employement, education, departmentOfLabor, socialSecurity, medicare
   
        
        var title : String { rawValue.camelCaseToWords() }
        
        var authorizationSuggestions : [Suggestion] {[ .medical, .employement, .education, .departmentOfLabor, .socialSecurity, .medicare ]}
    }
}
extension Case_OLD {
    var folderRootSuggestions : [Folder] {
        let rootNames = rootFolders.map(\.name)
        let suggestions = Folder.Suggestion.allCases.filter { !rootNames.contains($0.title) }
        return suggestions.compactMap { Folder(suggestion: $0)}
    }
}
