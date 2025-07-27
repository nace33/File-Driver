//
//  BOF_SwiftData.swift
//  TableTest
//
//  Created by Jimmy Nasser on 4/4/25.
//

import Foundation
import SwiftData

@MainActor
struct BOF_SwiftData {
    static let shared: BOF_SwiftData = { BOF_SwiftData() }() //Singleton
    var container: ModelContainer = {
        let schema = Schema([
            Sidebar_Item.self,
            FilerBlockText.self,
            FilerFolder.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

//MARK: Load
extension BOF_SwiftData {
    func loadDefaultSidebar() {
        let fetchDescriptor = FetchDescriptor<Sidebar_Item>()
        do {
            let defaultsFound =  try container.mainContext.fetch(fetchDescriptor)
            let expected = Sidebar_Item.defaults
            
            if defaultsFound.count != expected.count {
                for expect in expected {
                    if defaultsFound.filter({ $0.category == expect.category}).count == 0 {
                        container.mainContext.insert(expect)
                    }
                }
            }
        } catch {
            print("Error; \(error)")
        }
    }


    
   func fetch<T:PersistentModel>(_ descriptor: FetchDescriptor<T>) -> [T]? {
        try? container.mainContext.fetch(descriptor)
    }

}
