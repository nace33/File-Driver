//
//  ResearchList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI

struct Research_Content: View {
    @Environment(ResearchDelegate.self) var delegate
    @State private var showAddToCaseSheet = false
    
    var body: some View {
        VStackLoacker(loader: Bindable(delegate).loader) {
//            NavigationStack(path: Bindable(navModel).templatePath) {
                VStack(spacing:0) {
                    ResearchList(showFilter: true)
                        .contextMenu(forSelectionType: Research.ID.self,
                                     menu:          { listMenu($0 )      },
                                     primaryAction: { listDoubleClick($0)})
                        .searchable(text:   Bindable(delegate).filter.string,
                                    tokens: Bindable(delegate).filter.tokens,
                                    placement:.automatic,
                                    prompt: Text("Type to filter, or use #, $ for tags")) { token in
                            Text(token.title)
                        }
                        .searchSuggestions { delegate.filter.searchSuggestions }
                }
                    .frame(minWidth:300, idealWidth: 400)
                    .inspector(isPresented: .constant(true)) {
                        Research_Detail()
                            .inspectorColumnWidth(min: 500, ideal: 500)
                    }
//                    .navigationDestination(for: Template.ID.self) { templateID in
//                        if let template = delegate[templateID] {
//                            DriveFileView([template.file], isLoading: true, isPreview: false)
//                                .navigationTitle("Templates")
//                                #if os(macOS)
//                                .navigationSubtitle(template.title)
//                                #endif
//                        } else {
//                            Text("Could not locate template with id: \(templateID)")
//                        }
//                    }
//            }
        }
//            .sheet(item:$newTemplateType) { NewTemplate(from: $0)  }
//            .sheet(item: $duplicateItem)  {  DuplicateTemplate($0)  }
//            .sheet(isPresented: $showDriveImport) { ImportTemplate()  }
//            .sheet(item:$editItem) {
//                if let index = delegate.index(of: $0.id) {  EditTemplate( Bindable(delegate).templates[index])  }
//                else { Button("Unable to locate template") { editItem = nil }.padding() }
//            }
//            .sheet(isPresented:$showAddToCaseSheet) { AddTemplatesToCase() }
//            .confirmationDialog("Delete Template?", isPresented:.constant(trashItem != nil)) {  trashItemInDrive()  } message: {    trashMessage }
//            .confirmationDialog("Remove Template From List?", isPresented:.constant(removeItem != nil)) {  removeFromList()  } message: { removeMessage  }
            .disabled(delegate.loader.isLoading)
            .task { await delegate.loadItems() }
            .environment(delegate)
            .toolbar { toolbarContent  }
    }
}
//MARK: - Functions
extension Research_Content {
    func listDoubleClick(_ itemIDs:Set<Research.ID>) {
        print(#function + "\n\(itemIDs)")
    }
}


//MARK: - View Builders
extension Research_Content {
    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            //Refresh
            Button("", systemImage: "arrow.clockwise")  {  Task { await delegate.loadItems() } } .disabled(delegate.loader.isLoading)
            //New
//            Menu("New") {
//                ForEach(GTLRDrive_File.MimeType.googleTypes) { type in
//                    Button(type.title) { newTemplateType = type }
//                }
//                Divider()
//                Button("Import from Google Drive") { showDriveImport = true}
//            }
//            Menu("Edit") {
//                if let templateID = delegate.selectedIDs.first, let template = delegate[templateID] {
//                    if template.file.isGoogleType {
//                        Button(template.file.mime.title) { edit(delegate.selectedIDs.first!) }
//                    }
//                    Button("Label")    { editItem = template }
//                } else {
//                    Text("Nothing to edit.")
//                }
//            }
//                .disabled(delegate.selectedIDs.count != 1)
        }
        ToolbarItemGroup(placement: .primaryAction) {
            Button("Add To Case") { showAddToCaseSheet = true  }
                .disabled(delegate.selectedIDs.count == 0)
        }
    }
    @ViewBuilder func listMenu(_ itemIDs:Set<Research.ID>) -> some View {
        if itemIDs.count == 1, let research = delegate[itemIDs.first!]{
            Text(research.title)
//            Menu("Label Info") {
//                TemplateLabelDetail(template.label, style: .menu)
//            }
            Menu("Filter Settings") { ResearchFilter()}
//            Divider()
//            Button("Edit Label")     { editItem = template }
//            Button("Remove Label")   { removeItem = template }
//            Divider()
//            Button("Duplicate \(template.file.mime.title)") { duplicateItem = template }
//            Divider()
//            Button("Trash \(template.file.mime.title)") { trashItem = template}
        } else {
            ResearchFilter()
        }
    }
}

#Preview {
    Research_Content()
}
