//
//  FileDriver_URLScheme.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/31/25.
//

import Foundation

struct FileDriver_URLScheme {
    static let scheme : String = "filedriver"
    enum Action : String {
        case openDocument
    }
    static func create(category:Sidebar_Item.Category, action:Action, id:String) -> URL? {
//        print(#function)
//        print("category: \(category.title), Action: \(action.rawValue)/\(id)")
        return URL(string:"\(scheme)://\(category.rawValue)/\(action.rawValue)/\(id)?caseID=123")
    }
    static func handle(_ url:URL) {
        guard url.scheme == scheme else { return } //invalid Scheme
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return } //invalid URL
        guard let host = components.host, let category = Sidebar_Item.Category(rawValue: host) else { return  } //no sidebar item found
        
        print("Sidebar Category: \(category.title)")
        
        
//        guard let action = components.host, action == "open-recipe" else {
//                  print("Unknown URL, we can't handle this one!")
//                  return
//              }
        guard let caseID = components.queryItems?.first(where: { $0.name == "caseID" })?.value else {
                 print("Recipe name not found")
                 return
             }
        print("caseID: \(caseID)")
//        print("Components: \(components)")
    }
    
    
}
