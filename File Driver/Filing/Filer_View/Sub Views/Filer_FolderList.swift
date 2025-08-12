//
//  Filer_FolderList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/21/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct Filer_FolderList: View {
    @Environment(Filer_Delegate.self) var delegate
    var body: some View {
        ScrollViewReader { proxy in
            List(selection:Bindable(delegate).folderListSelection) {
                if delegate.folders.isEmpty {
                    Text("No Folders in this directory.").foregroundStyle(.secondary)
                }
                ForEach(filteredFolders, id:\.self) { folder in
                    Label {
                        Text(folder.title)
                    } icon: {
                        Image(folder.mime.title)
                            .resizable()
                            .scaledToFit()
                    }
                    .tag(folder.id)
                }
                .listRowSeparator(.hidden)
            }
            .onChange(of: delegate.folderListScrollID) { _, newID in  proxy.scrollTo(newID)  }
            .onChange(of: delegate.folderListSelection, { oldValue, newValue in
                if newValue == nil && delegate.stack.count > 1 {
                    delegate.folderListSelection = delegate.stack.last
                }
            })
            .contextMenu(forSelectionType: GTLRDrive_File.self, menu: { items in
                if let item = items.first {
                    Button("Select") { delegate.select(item) }
                }
            }, primaryAction: { items in
                if let item = items.first {
                    delegate.load(item)
                }
            })
        }
    }
    

    var filteredFolders : [GTLRDrive_File] {
        guard delegate.filterString.count > 0 else { return delegate.folders }
        return delegate.folders.filter { $0.title.ciContain(delegate.filterString)}
    }
}


