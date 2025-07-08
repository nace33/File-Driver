//
//  Filer_DriveList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/2/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct FileToCase_DriveList: View {
    @Environment(FileToCase_Delegate.self) var delegate
    
    
    var body: some View {
        ScrollViewReader { proxy in
            List(selection:Bindable(delegate).selectedFolder) {
                if delegate.folders.isEmpty { Text("Folder is empty.").foregroundStyle(.secondary)}
                ForEach(delegate.filteredFolders, id:\.self) { folder in
                    Label {
                        Text(folder.title)
                    } icon: {
                        Image(folder.mime.title)
                            .resizable()
                            .scaledToFit()
                    }
                        .tag(folder.id)
                }
            }
                .onChange(of: delegate.scrollToFolderID) { _, newID in  proxy.scrollTo(newID)  }
                .onChange(of: delegate.selectedFolder, { oldValue, newValue in
                    if newValue == nil, delegate.stack.count > 1 { delegate.selectedFolder = delegate.stack.last}
                })
                .alternatingRowBackgrounds()
                .contextMenu(forSelectionType: GTLRDrive_File.self, menu: {_ in}, primaryAction: { items in
                    if let item = items.first {
                        delegate.doubleClicked(item)
                    }
                })
        }
    }
}

