//
//  TemplatesView2.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/8/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct Templates_Content: View {
    @Environment(TemplatesDelegate.self) var delegate
    @Environment(BOF_Nav.self) var navModel
    @State private var editItem : Template?
    @State private var duplicateItem : Template?
    @State private var showDriveImport = false
    @State private var showAddToCaseSheet   = false
    @State private var newTemplateType      : GTLRDrive_File.MimeType?
    @State private var trashItem : Template?
    @State private var removeItem : Template?

    var body: some View {
        VStackLoacker(loader: Bindable(delegate).loader) {
            NavigationStack(path: Bindable(navModel).templatePath) {
                VStack(spacing:0) {
                    TemplatesList(showFilter: true)
                        .contextMenu(forSelectionType: Template.ID.self,
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
                        Templates_Detail()
                            .inspectorColumnWidth(min: 500, ideal: 500)
                    }
                    .navigationDestination(for: Template.ID.self) { templateID in
                        if let template = delegate[templateID] {
                            DriveFileView([template.file], isLoading: true, isPreview: false)
                                .navigationTitle("Templates")
                                #if os(macOS)
                                .navigationSubtitle(template.title)
                                #endif
                        } else {
                            Text("Could not locate template with id: \(templateID)")
                        }
                    }
            }
        }
            .sheet(item:$newTemplateType) { NewTemplate(from: $0)  }
            .sheet(item: $duplicateItem)  {  DuplicateTemplate($0)  }
            .sheet(isPresented: $showDriveImport) { ImportTemplate()  }
            .sheet(item:$editItem) {
                if let index = delegate.index(of: $0.id) {  EditTemplate( Bindable(delegate).templates[index])  }
                else { Button("Unable to locate template") { editItem = nil }.padding() }
            }
            .sheet(isPresented:$showAddToCaseSheet) { AddTemplatesToCase() }
            .confirmationDialog("Delete Template?", isPresented:.constant(trashItem != nil)) {  trashItemInDrive()  } message: {    trashMessage }
            .confirmationDialog("Remove Template From List?", isPresented:.constant(removeItem != nil)) {  removeFromList()  } message: { removeMessage  }
            .disabled(delegate.loader.isLoading)
            .task { await delegate.loadTemplates() }
            .environment(delegate)
            .toolbar { toolbarContent  }
    }
}


//MARK: - Functions
extension Templates_Content {
    func edit(_ templateID:Template.ID) {
        navModel.templatePath.append(templateID)
    }
    func listDoubleClick(_ templateIDs:Set<Template.ID>) {
        if templateIDs.count == 1,
            let templateID = templateIDs.first {
            edit(templateID)
        }
    }

}


//MARK: - ViewBuilders
extension Templates_Content {
    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            //Refresh
            Button("", systemImage: "arrow.clockwise")  {  Task { await delegate.loadTemplates() } } .disabled(delegate.loader.isLoading)
            //New
            Menu("New") {
                ForEach(GTLRDrive_File.MimeType.googleTypes) { type in
                    Button(type.title) { newTemplateType = type }
                }
                Divider()
                Button("Import from Google Drive") { showDriveImport = true}
            }
            Menu("Edit") {
                if let templateID = delegate.selectedIDs.first, let template = delegate[templateID] {
                    if template.file.isGoogleType {
                        Button(template.file.mime.title) { edit(delegate.selectedIDs.first!) }
                    }
                    Button("Label")    { editItem = template }
                } else {
                    Text("Nothing to edit.")
                }
            }
                .disabled(delegate.selectedIDs.count != 1)
        }
        ToolbarItemGroup(placement: .primaryAction) {
            Button("Add To Case") { showAddToCaseSheet = true  }
                .disabled(delegate.selectedIDs.count == 0)
        }
    }
    @ViewBuilder func listMenu(_ templateIDs:Set<Template.ID>) -> some View {
        if templateIDs.count == 1, let template = delegate[templateIDs.first!]{
            Menu("Label Info") {
                TemplateLabelDetail(template.label, style: .menu)
            }
            Menu("Filter Settings") { TemplatesFilter(style: .menu)}
            Divider()
            Button("Edit Label")      { editItem = template }
            Button("Remove Label") { removeItem = template }
            Divider()
            Button("Duplicate \(template.file.mime.title)") { duplicateItem = template }
            Divider()
            Button("Trash \(template.file.mime.title)") { trashItem = template}
        } else {
            TemplatesFilter(style: .menu)
        }
    }

}


//MARK: - Trash & Remove
extension Templates_Content {
    @ViewBuilder var  trashMessage : Text {
        Text("This will move the file to Google Drive's Trash.  It can be recovered within 30 days.")
    }
    @ViewBuilder func trashItemInDrive() -> some View {
        if let template = delegate.templates.first(where: {$0.id == trashItem?.id}) {
            Button("Trash", role:.destructive) {
                Task { try? await delegate.trash(template)}
                self.trashItem = nil
            }
        }
        Button("Cancel", role: .cancel) { self.trashItem = nil}
    }
    @ViewBuilder var  removeMessage : Text {
        Text("The file will still exist in Google Drive and can be re-added to the Template's list at any time.")
    }
    @ViewBuilder func removeFromList() -> some View {
        if let template = delegate.templates.first(where: {$0.id == removeItem?.id}) {
            Button("Remove", role:.destructive) {
                Task { try? await delegate.removeLabel(template) }
                self.removeItem = nil
            }
        }
        Button("Cancel", role: .cancel) {self.removeItem = nil }
    }
}
