//
//  BOF_NavModel.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/4/25.
//

import SwiftUI

@Observable
final class BOF_Nav : Codable, RawRepresentable{
    static let storageKey: String = "File-Driver_BOF_Nav"

    var sidebarID : Sidebar_Item.ID? = nil

    //Cases
    var casePath = NavigationPath()
    var caseID  : Case.ID?
    var caseView : Case.ViewIndex = .allCases.first!
    
    //Templates
    var templatePath = NavigationPath()

    enum CodingKeys: String, CodingKey {
        case sidebar, casePath, caseID, caseView, templatePath
    }
    
    init() {
        self.sidebarID = nil
    }
    
    
    //MARK: Codable
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sidebarID = try container.decodeIfPresent(Sidebar_Item.ID.self, forKey: .sidebar)
        self.caseID = try container.decodeIfPresent(Case.ID.self, forKey: .caseID)
        self.caseView = try container.decodeIfPresent(Case.ViewIndex.self, forKey: .caseView) ?? .allCases.first!
        
        if let data = try container.decodeIfPresent(NavigationPath.CodableRepresentation.self, forKey: .casePath) {
            self.casePath = .init(data)
        }
        if let data = try container.decodeIfPresent(NavigationPath.CodableRepresentation.self, forKey: .templatePath) {
            self.templatePath = .init(data)
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(sidebarID, forKey: .sidebar)
        try container.encodeIfPresent(casePath.codable, forKey: .casePath)
        try container.encodeIfPresent(caseID, forKey: .caseID)
        try container.encodeIfPresent(caseView, forKey: .caseView)
      
        //Templates
        try container.encodeIfPresent(templatePath.codable, forKey: .templatePath)

        
    }
    
    //MARK: RawRepresentable
    ///So NavigationModel can be stored in SceneStorage
    init(rawValue: String) {
         guard let data = rawValue.data(using: .utf8),
             let result = try? JSONDecoder().decode(BOF_Nav.self, from: data)
         else {
             return
         }
         self.sidebarID = result.sidebarID
         self.casePath    = result.casePath
        self.caseID  = result.caseID
        self.caseView  = result.caseView
        
        //Templates
        self.templatePath = result.templatePath
    }

     var rawValue: String {
         guard let data = try? JSONEncoder().encode(self),
             let result = String(data: data, encoding: .utf8)
         else {
             return "[]"
         }
         return result
     }
}
