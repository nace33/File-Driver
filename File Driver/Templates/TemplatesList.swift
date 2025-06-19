//
//  FormsList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

struct TemplatesList: View {
    @Environment(TemplatesController.self) var controller
    @Environment(\.openURL) var openURL

    @State private var newTemplateType      : GTLRDrive_File.MimeType?
    @State private var showImport           : Bool = false
    @State private var editTemplate         : Template?
    @State private var duplicateTemplate    : Template?

    @AppStorage(BOF_Settings.Key.templateDriveID.rawValue)        var driveID       : String = ""
    @AppStorage(BOF_Settings.Key.templatesShowDrafting.rawValue)  var showDrafting  : Bool = true
    @AppStorage(BOF_Settings.Key.templatesShowActive.rawValue)    var showActive    : Bool = true
    @AppStorage(BOF_Settings.Key.templatesShowRetired.rawValue)   var showRetired   : Bool = true
    @AppStorage(BOF_Settings.Key.templatesSortKey.rawValue)       var sortKey       : Bool = true
    @AppStorage(BOF_Settings.Key.templatesListSort.rawValue)           var listSort      : Template.Sort = .category
    @State private var driveDelegate = Google_DriveDelegate.selecter(mimeTypes: [.folder])

    var body: some View {
        HSplitView {
            if driveID.isEmpty {
                setDriveIDView
            }
            else if controller.isLoading {
                loadingView
            }
            else if controller.templates.isEmpty {
                noTemplatesView
            }
            else {
                listView
                    .alternatingRowBackgrounds()
                    .frame(minWidth:400, idealWidth: 400, maxWidth: 400)
                    .contextMenu(forSelectionType: Template.ID.self,
                                 menu:          { listMenu($0 )      },
                                 primaryAction: { listDoubleClick($0)})
                Group {
                    if controller.selectedIDs.count > 1 {
                        TemplatesDetail(ids: controller.selectedIDs)
                    }
                    else if let index = controller.selectedIndex {
                        TemplateDetail(Bindable(controller).templates[index])
                    } else {
                        ContentUnavailableView("No Selection", systemImage: "filemenu.and.selection", description: Text("Select a template from the list on the left."))
                    }
                }
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
            .sheet(item: $newTemplateType) { mimeType in
                NewTemplate(from:mimeType)
            }
            .sheet(item: $editTemplate) { template in
                if let index = controller.index(of: template) {
                    EditTemplate(Bindable(controller).templates[index])
                } else {
                    Button("Ooopsies!") { editTemplate = nil}.padding(100)
                }
            }
            .sheet(item: $duplicateTemplate) { template in
                DuplicateTemplate(template)
            }
            .sheet(isPresented: $showImport)   {
                ImportTemplate()
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                   newMenu
                }
            }
            .task { await controller.loadTemplates() }
    }
}


//MARK: - Properties
extension TemplatesList {
    var filteredTemplates: [Template] {
        let filter = controller.filter
        return controller.templates.filter { contact in
            if !showDrafting, contact.label.status == .drafting  { return false }
            if !showActive,  contact.label.status == .active  { return false }
            if !showRetired ,  contact.label.status == .retired   { return false }
            
            if !filter.string.isEmpty, !filter.hasTokenPrefix, !contact.title.ciContain(filter.string) { return false   }
            if !filter.tokens.isEmpty {
                for token in filter.tokens {
                    if token.prefix == .hashTag {
                        if contact.label.category != token.rawValue { return false }
                    } else if token.prefix == .dollarSign {
                        if contact.label.subCategory != token.rawValue { return false }
                    }
                }
            }
            return true
        }
    }
    var groupKey : KeyPath<Template,String> {
        switch listSort {
        case .alphabetically:
            \.title
        case .category:
            \.label.category
        case .subCategory:
            \.label.subCategory
        }
    }
    var isAlphabetic : Bool { listSort == .alphabetically }
}


//MARK: - Actions
extension TemplatesList {
    func openInTab(_ template:Template) {
        File_DriverApp.createWebViewTab(url: template.file.editURL, title: template.title)
    }
    func openInBrowser(_ template:Template) {
        openURL(template.file.editURL)
    }
    func listDoubleClick(_ items:Set<Template.ID>) {
        if let id = items.first, let template = controller[id] {
            openInTab(template)
        }
    }
}


//MARK: - View Builders
extension TemplatesList {
    //Toolbar
    @ViewBuilder var newMenu         : some View {
        Menu {
            Button("Google Doc")   { newTemplateType = .doc  }
            Button("Google Sheet") { newTemplateType = .sheet}
            Divider()
            Button("Import From Drive")       { showImport.toggle()}
        } label: {
            Text("New")
        }
            .fixedSize()
            .padding(.leading)
    }
    @ViewBuilder var setDriveIDView : some View {
        Google_DriveView("Select a drive to save Contacts in", delegate: $driveDelegate, canLoad: { _ in false})
            .onChange(of: driveDelegate.selectItem) { _, newValue in
                if let newValue, newValue.id == newValue.driveId {
                    self.driveID = newValue.id
                    Task { await controller.loadTemplates() }
                }
            }
    }

    @ViewBuilder var noTemplatesView : some View {
        VStack {
            Spacer()
            Text("Create your first \(controller.title)!")
            newMenu
            Spacer()
        }
    }
    @ViewBuilder var noFilteredTemplatesView : some View {
        if controller.filter.isEmpty {
            Menu {
                listOptionsButtons
            } label: {
                Text("- \(controller.templates.count ) templates are hidden -")
                    .foregroundStyle(.blue)
            }
                .fixedSize()
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .padding(.vertical)

        } else {
            Text("No Templates")
                .foregroundStyle(.secondary)
                .padding(.vertical)
        }
    }
    @ViewBuilder var loadingView  : some View {
        VStack {
            Spacer()
            ProgressView("Loading \(controller.title)s")
            Spacer()
        }
    }
    @ViewBuilder var listView     : some View {
        VStack(spacing:0) {
            let filteredTemplates = filteredTemplates
            ScrollViewReader { proxy in
                List(selection: Bindable(controller).selectedIDs) {
                    if filteredTemplates.isEmpty {  noFilteredTemplatesView }

                    
                    BOFSections(of:filteredTemplates, groupedBy:groupKey, isAlphabetic: isAlphabetic) { category in
                        Text(category.isEmpty ? "NO SUBCATEGORY" : category.uppercased())
                    } row: { template in
                        templateRow(template)
                    }
                        .listRowSeparator(.hidden)
                }
                    .listStyle(.sidebar)
                    .onChange(of: controller.scrollToID) { _, newID in  proxy.scrollTo(newID)  }
                    .searchable(text:   Bindable(controller).filter.string,
                                tokens: Bindable(controller).filter.tokens,
                                placement:.sidebar,
                                prompt: Text("Type to filter, or use #, $ for tags")) { token in
                        Text(token.title)
                    }
                    .searchSuggestions { controller.filter.searchSuggestions }
            }
            Filter_Footer(count: filteredTemplates.count, title:"Templates") {
                Form {
                    LabeledContent("Show") { listOptionsButtons }
                    listSortPicker
                }
            }
        }
    }
    @ViewBuilder func templateRow(_ template:Template) -> some View {
        Label {
            Text(template.title)
                .foregroundStyle(template.label.status.color)
                .padding(.leading, 4)
        } icon: {
            template.file.icon
        }
    }
    @ViewBuilder func templateBoundRow(_ template:Binding<Template>) -> some View {
        Label {
            Text(template.wrappedValue.title)
                .foregroundStyle(template.wrappedValue.label.status.color)
                .padding(.leading, 4)
        } icon: {
            template.wrappedValue.file.icon
        }
    }
    @ViewBuilder func listMenu(_ items:Set<Template.ID>)    -> some View {
        if items.isEmpty {
            Menu("Show") {listOptionsButtons}
            listSortPicker
        }
        else if let id = items.first, let template = controller[id] {
            Button("Open") { openInTab(template) }
            Button("Open in Browser") { openInBrowser(template)}
            Divider()
            Button("Edit") { editTemplate = template }
            Divider()
            Button("Duplicate") { duplicateTemplate = template}
        }
    }
    @ViewBuilder var listOptionsButtons : some View {
        Toggle("Drafting", isOn: $showDrafting).foregroundStyle(.yellow)
            .padding(.trailing, 8)
        Toggle("Active", isOn: $showActive)
            .padding(.trailing, 8)
        Toggle("Retired", isOn: $showRetired).foregroundStyle(.red)

    }
    @ViewBuilder var listSortPicker : some View {
        Picker("Sort By", selection:$listSort) {
            ForEach(Template.Sort.allCases, id:\.self) { sort in
                Text(sort.rawValue.capitalized).tag(sort)
            }
        }
            .fixedSize()
    }

}

public struct BOFBoundSections<T:Identifiable & Hashable, V:View, G:Hashable & Comparable> : View {
    var items : Binding<[T]>
    var key   : KeyPath<T, G>
    var header : (G) -> Text
    var row     : (Binding<T>) -> V
    var sections : [G]
    let isAlphabetic : Bool
    public init(of items: Binding<[T]>, groupedBy groupKey: KeyPath<T, G>, @ViewBuilder header:@escaping (G) -> Text, @ViewBuilder row:@escaping (Binding<T>) -> V) {
        self.items = items
        self.key = groupKey
        self.header = header
        self.row = row
        isAlphabetic = false
        self.sections = items.compactMap { $0.wrappedValue[keyPath:groupKey] }.unique().sorted()
    }
    public init(of items: Binding<[T]>, groupedBy groupKey: KeyPath<T, G>, isAlphabetic:Bool = false, @ViewBuilder header:@escaping (G) -> Text, @ViewBuilder row:@escaping (Binding<T>) -> V) where G == String {
        self.items = items
        self.key = groupKey
        self.header = header
        self.row = row
        self.isAlphabetic = isAlphabetic
        if isAlphabetic {
           // self.sections = (0...25).compactMap { $0.letter }
            //Using above means any non-alphabetic filename is never matched
            self.sections = items.compactMap { $0.wrappedValue[keyPath:groupKey][0]}.unique().sorted(by: {$0.uppercased() < $1.uppercased()})
        } else {
            self.sections = items.compactMap { $0.wrappedValue[keyPath:groupKey] }.unique().sorted(by: {$0.uppercased() < $1.uppercased()})
        }
    }
    
    func matches(for section:G) -> Binding<[T]> {
        return Binding {
            if isAlphabetic, let letter = section as? String {
                return items.wrappedValue.filter {
                    if let value = $0[keyPath:key] as? String {
                        return value.lowercased().hasPrefix(letter.lowercased())
                    } else {
                        return false
                    }
                }
            }
            return items.wrappedValue.filter { $0[keyPath:key] == section }
        } set: { newValue in
            
        }
    }
    public var body: some View {
        ForEach(sections, id:\.self) { section in
            let matches = matches(for: section)
            if !matches.isEmpty {
                Section {
                    ForEach(matches) { match in
                        row(match)
                    }
                } header: {
                    header(section)
                }
            }
        }
    }
}
