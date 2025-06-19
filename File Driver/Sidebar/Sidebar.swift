//
//  Sidebar.swift
//  TableTest
//
//  Created by Jimmy Nasser on 4/4/25.
//
import SwiftUI
import SwiftData


struct Sidebar : View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter:#Predicate<Sidebar_Item> { $0.parent == nil }, sort:\Sidebar_Item.order) private var roots: [Sidebar_Item]
    @Query(sort:\Sidebar_Item.order) private var items: [Sidebar_Item]
    @State private var showAddSheet = false
    @State private var editItem: Sidebar_Item?
    @Environment(BOF_Nav.self) var navigation
    @Environment(\.openWindow) var openWindow
    @State private var listDropTargeted : Bool = false
    
    var body: some View {
        List(selection:Bindable(navigation).sidebar) {
            ForEach(roots) { root in
                if let children = sortedChildren(root), children.isNotEmpty {
                    Section(isExpanded: Bindable(root).isExpanded) {
                        ForEach(children) { child in
                            Sidebar_Row(item: child)
                                .padding(.leading, 8)
                                .draggable(child.id.self)
                                .contextMenu { menu(child)}
                                //Children are not drop destinations
                        }
                            .onMove(perform: root.move)
                    } header : {
                        Text(root.title)
                            .padding(.top, 10)
                            .dropDestination(for: Sidebar_Item.ID.self) { droppedIDs, _ in
                                move(droppedIDs: droppedIDs, to: root)
                            } 
                            .contextMenu {rootMenu(root) }
                    }
                    
                } else if !root.isHidden && !root.childrenAreAllHidden {
                    if root.isGroup { //This likely does not exist, since a group has child items and be handled above
                        Sidebar_Row(item: root)
                            .contextMenu { menu(root)}
                    } else {
                        Sidebar_Row(item: root)
                            .contextMenu { menu(root)}
                            .draggable( root.id.self)
                            .dropDestination { droppedIDs, _ in
                                createNewGroup(item1:root, droppedIDs:droppedIDs)
                            }

                    }
                }
            }
                .onMove(perform: move)
        }
            .frame(minWidth:205)
            .dropDestination(for: Sidebar_Item.ID.self) { droppedIDs, _ in
                removeFromGroup(droppedIDs)
            } isTargeted: { listDropTargeted = $0 }
            .dropStyle(isTargeted: $listDropTargeted)
            .sheet(isPresented: $showAddSheet) { SidebarItem_New() }
            .sheet(item: $editItem) { SidebarItem_Edit($0)}
            .contextMenu { listMenu() }
        
//            .toolbar {
//                ToolbarItem(placement:.primaryAction) {
//                    Menu("New") {
//                        Button("Sidebar Item") { showAddSheet.toggle() }
//                    }
//                }
//            }
    }

}


//MARK: Properties
fileprivate
extension Sidebar {
    var groups : [Sidebar_Item] { roots.filter { $0.isGroup}  }
    func sortedChildren(_ item:Sidebar_Item) -> [Sidebar_Item]? {
       var kids = item.sortedChildren
        kids = kids.filter { $0.isHidden == false }
        return kids.isEmpty ? nil : kids
    }
}

//MARK: Methods
fileprivate
extension Sidebar {
    //Groups
    //add item to non-existent group
    func addToNewGroup(_ item:Sidebar_Item) {
        let groupNumber = groups.count
        let groupName = "Group \(groupNumber + 1)"
        //Set group order to item it is replacing
        let groupOrder = item.order
        //reset order to first order in group
        item.order = 0
        let group = Sidebar_Item(group:groupName, order: groupOrder, children: [item])
        modelContext.insert(group)
        try? modelContext.save()
    }
    func createNewGroup(item1:Sidebar_Item, droppedIDs:[Sidebar_Item.ID]) -> Bool {
        if item1.parent != nil {
            removeFromGroup(item1)
        }
       
        let groupOrder = item1.order
        var index = 0
        item1.order = index
        index += 1
        var droppedItems : [Sidebar_Item] = droppedIDs.compactMap { id in items.first(where: {$0.id == id }) }
        for droppedItem in droppedItems {
            if droppedItem.parent != nil {
                removeFromGroup(droppedItem)
            }
            droppedItem.order = index
            index += 1
        }
        droppedItems.insert(item1, at: 0)
        
        let groupNumber = groups.count
        let groupName = "Group \(groupNumber + 1)"
        
        let group = Sidebar_Item(group:groupName, order: groupOrder, children: droppedItems)
        modelContext.insert(group)
        try? modelContext.save()
        return true
    }
    
    //move item to existing group
    func move(item:Sidebar_Item, to parent:Sidebar_Item) -> Bool {
        guard item.parent?.id != parent.id else { return false }
        let sortedChildren = parent.sortedChildren

        if let order = sortedChildren.last?.order {
            item.order = order + 1
        } else { item.order = 0 }
        parent.children?.append(item)
        return true
    }
    func move(droppedIDs:[Sidebar_Item.ID], to parent:Sidebar_Item) -> Bool {
        var didMove = false
        for id in droppedIDs {
            if let droppedItem = items.first(where: {$0.id == id }) {
                guard !droppedItem.isGroup else { return false }
                guard droppedItem.parent?.id != parent.id else { return false }
                if droppedItem.parent != nil {
                    removeFromGroup(droppedItem)
                }
                didMove = move(item:droppedItem, to:parent)
                if !didMove { break}
            }
        }
        return didMove
    }
    
    //remove item from existing group
    func removeFromGroup(_ item:Sidebar_Item) {
        guard let parent = item.parent else { return }
        let children =  parent.sortedChildren
        if children.count == 1 {
            item.order  = parent.order
            item.parent = nil
            modelContext.delete(parent)
        } else if parent.children?.remove(item) ?? false {
            let newOrder = roots.last?.order ?? 0
            item.order = newOrder + 1
        }
    }
    func removeFromGroup(_ droppedIDs:[Sidebar_Item.ID]) -> Bool {
        var didMove = false
        droppedIDs.forEach { id in
            if let droppedItem = items.first(where: {$0.id == id }) {
                removeFromGroup(droppedItem)
                didMove = true
            }
        }
        return didMove
    }
    
    //Re-order Roots in List
    //children re-order done in the move() function of Sidebar_Item
    func move(from source: IndexSet, to destination: Int) {
        var items = self.roots
        items.move(fromOffsets: source, toOffset: destination)
        items.indices.forEach { index in
            items[index].order = index
        }
        try? modelContext.save()
    }
    
    //eligible new items
    var eligibleCategories : [Sidebar_Item.Category] {
        let existing = items.map(\.category)
        return Sidebar_Item.Category.allCases.filter { !existing.contains($0)}
    }
    func insertEligible(_ category:Sidebar_Item.Category) {
        let order = items.compactMap(\.order).max(by: {$0 > $1}) ?? -1
        let newItem = Sidebar_Item(url: category.defaultURL, title:category.title, category: category, order: order + 1)
        modelContext.insert(newItem)
    }
    func resortItems() {
        var index = 0
        let groups = roots
        for group in groups {
            group.order = index
            var childIndex = 0
            for child in group.sortedChildren {
                child.order = childIndex
                childIndex += 1
            }
            index += 1
        }
 
        printOrder()
    }
    func printOrder() {
        for item in self.items {
            print("\(item.order): \(item.title)")
        }
    }
}


//MARK: View Builders
fileprivate
extension Sidebar {
    @ViewBuilder func rootMenu(_ item:Sidebar_Item) -> some View {
        Button("Edit") { editItem = item }
    }
    @ViewBuilder func menu(_ item:Sidebar_Item) -> some View {
        Button("Edit") { editItem = item }
        Button("Open In New Window") { openWindow(id: "default", value: item.id)  }

        if !item.isDefault && !item.isGroup {
            Menu("Favicon") {
                if item.url.faviconURL(size: .xl) != nil {
                    Button("Download Favicon") { item.downloadFavicon()}
                }
                if item.iconData != nil {
                    Button("Remove Favicon") { item.iconData = nil}
                }
            }
        }
 
        Menu("Groups") {
            let groups = groups.filter { item.parent?.id != $0.id}
            if groups.isNotEmpty {
                Menu("Move To") {
                    ForEach(groups) { group in Button(group.title) { _ = move(item: item, to: group) }}
                }
            }
            if item.parent == nil {
                Button("Add To New Group") { addToNewGroup(item) }
            } else {
                Button("Remove from Group") {removeFromGroup(item) }
            }
        }

      
        Divider()
        if item.category != .settings {
            Button("Hide") { item.isHidden = true }
        }
        if !item.isDefault {
            Button("Delete") {  modelContext.delete(item)  }
        }
    }
    @ViewBuilder func listMenu() -> some View {
        newSidebarItemMenu()
        Divider()
        Button("Re-Sort Items")   { resortItems() }
        Button("Log Item Iorder") { printOrder() }
    }
    @ViewBuilder func newSidebarItemMenu() -> some View {
        let eligibleCategories = eligibleCategories
        if eligibleCategories.isNotEmpty {
            Menu("Add Sidebar Item") {
                Button("Custom") { showAddSheet.toggle() }
                Divider()
                ForEach(eligibleCategories, id:\.self) { cat in
                    Button(cat.title) {
                        insertEligible(cat)
                    }
                }
            }
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Sidebar_Item.self, inMemory: true)
  
}
