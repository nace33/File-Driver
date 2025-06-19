//
//  Item.swift
//  TableTest
//
//  Created by Jimmy on 4/3/25.
//

import Foundation
import SwiftData

@Model
final class Sidebar_Item : Identifiable {
    var id              : String = ""
    var title           : String = ""
    var url             : URL    = URL(string:"Hello World")!
    var categoryString  : String = Sidebar_Item.Category.group.rawValue
    var iconData        : Data?  = nil
    var order           : Int    = 0
    var isHidden        : Bool   = false
    var isExpanded      : Bool   = true
    
    //Relationships
    var parent      : Sidebar_Item? = nil
    @Relationship(deleteRule: .cascade, inverse:\Sidebar_Item.parent) var children : [Sidebar_Item]? = nil
    
    //Computed
    var category  : Sidebar_Item.Category {
        get { Sidebar_Item.Category(rawValue: categoryString) ?? .group }
        set { categoryString = newValue.rawValue }
    }
    var isDefault : Bool { Sidebar_Item.Category.defaults.contains(category)}
    var isGroup   : Bool { category == .group }
    var sortedChildren : [Sidebar_Item] {
        children?.sorted(by:{$0.order < $1.order}) ?? []
    }
    
    //INITs
    init(url:URL, title:String, category:Sidebar_Item.Category, order:Int) {
        self.id = UUID().uuidString
        self.url = url
        self.title = title
        self.categoryString = category.rawValue
        self.order = order

    }
 
    convenience init(group:String, order:Int, children:[Sidebar_Item]) {
        let uStr = group.replacingOccurrences(of: " ", with: "")
        let url = URL(string:uStr)!
        self.init(url: url, title: group, category:.group, order: order)
        self.children = children
    }
    
    
    static var defaults : [Sidebar_Item] {
        var index = 0
        return Sidebar_Item.Category.defaults.compactMap {
            let item = Sidebar_Item(url: $0.defaultURL, title: $0.title, category:$0, order: index)
            index += 1
            return item
        }
    }
    var childrenAreAllHidden : Bool {
        guard let children, children.count > 0 else { return false }
        return children.filter({ $0.isHidden == false }).count == 0
    }
    func move(from source: IndexSet, to destination: Int) {
        guard var items = children else { return }
        items = items.sorted(by: {$0.order < $1.order})
        items.move(fromOffsets: source, toOffset: destination)
        items.indices.forEach { index in
            items[index].order = index
        }
    }
}

//MARK: Types
extension Sidebar_Item {
    enum Category : String, CaseIterable {
        case filing, templates, cases, contacts, tasks, research, settings
        case inbox, calendar, drive, gemini
        case user, group, doc, sheet, driveQuery, folder, reports
        var iconString : String {
            switch self {
            case .filing:
                "cabinet"
            case .templates:
                "doc.badge.gearshape"
            case .cases:
                "briefcase"
            case .contacts:
                "person.2"
            case .tasks:
                "checkmark.square"
            case .settings:
                "gear"
            case .inbox:
                "envelope"
            case .calendar:
                "calendar"
            case .drive:
                "externaldrive.badge.icloud"
            case .gemini:
                "brain"
            case .user:
                "globe"
            case .group:
                "rectangle.3.group"
            case .doc:
                "file.fill"
            case .sheet:
                "gridcell.3x2"
            case .driveQuery:
                "mail.and.text.magnifyingglass.rtl"
            case .folder:
                "folder"
            case .research:
                "magnifyingglass"
            case .reports:
                "barchart.fill"
            }
        }
        var title : String { rawValue.camelCaseToWords()}
        var defaultURL : URL {
            switch self {
            case .filing:
                URL(string:"default://\(rawValue)")!
            case .cases:
                URL(string:"default://\(rawValue)")!
            case .tasks:
                URL(string:"default://\(rawValue)")!
            case .settings:
                URL(string:"default://\(rawValue)")!
            case .inbox:
                URL(string:"https://mail.google.com")!
            case .calendar:
                URL(string:"https://calendar.google.com")!
            case .drive:
                URL(string:"https://drive.google.com")!
            case .gemini:
                URL(string:"https://gemini.google.com")!
            default:
                URL(string:"user://someAmazing\(rawValue)URL")!
            }
        }
        static var defaults       : [Category] { nlfDefaults + googleDefaults}
        static var nlfDefaults    : [Category] {[ .filing, .templates, .cases, .contacts, .tasks, .research, .settings,  ]}
        static var googleDefaults : [Category] {[ .inbox, .calendar, .drive, .gemini  ]}
    }
}


//MARK: Favicon
extension Sidebar_Item {
    @MainActor
    func downloadFavicon() {
        guard let iconURL = url.absoluteString.validURL?.faviconURL(size:.xl) else { return }
        Task {
            let request = URLRequest(url:iconURL)
            if let result = try? await URLSession(configuration: .default).data(for:request ) {
                self.iconData = result.0
                URLSession.shared.configuration.urlCache?.removeCachedResponse(for: request)
            }
        }
    }
}


//MARK: Fetch
extension Sidebar_Item {
    static func fetchItem(with id:Sidebar_Item.ID?, in context:ModelContext) -> Sidebar_Item? {
        guard let id else { return nil }
        var fetchDescriptor = FetchDescriptor<Sidebar_Item>(predicate: #Predicate { id == $0.id })
            fetchDescriptor.fetchLimit = 1
        do {
            return try context.fetch(fetchDescriptor).first
        } catch {
            return nil
        }
    }
}
