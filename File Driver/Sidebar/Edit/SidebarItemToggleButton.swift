//
//  SidebarItemToggleButton.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import SwiftUI
import SwiftData

struct SidebarItemToggleButton : View {
    let url : URL
    let category : Sidebar_Item.Category
    let title : String
    @Environment(\.modelContext) private var modelContext
    @Query(sort:\Sidebar_Item.order) private var sidebarItems: [Sidebar_Item]
    
    var body: some View {
        if existingItem == nil {
            Button("Add To Sidebar") {
                addToSidebar()
            }
        } else {
            Button("Remove From Sidebar") {
                removeFromSidebar()
            }
        }
    }
    func addToSidebar() {
        let order = sidebarItems.last?.order ?? 0
        let newItem = Sidebar_Item(url:url, title:title, category:category, order:order + 1)
        modelContext.insert(newItem)
    }
    var existingItem : Sidebar_Item? {
        sidebarItems.first(where: {  $0.url.absoluteString == url.absoluteString && $0.category == category   })
    }
    func removeFromSidebar() {
        if let existingItem  {
            modelContext.delete(existingItem)
        }
    }
}
