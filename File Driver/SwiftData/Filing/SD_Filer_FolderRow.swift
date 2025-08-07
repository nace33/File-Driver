//
//  SD_Filer_FolderRow.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/29/25.
//

import SwiftUI
import SwiftData

struct SD_Filer_FolderRow: View {
    let folder : FilerFolder
    @Environment(\.modelContext) var context

    var body: some View {
        Text(folder.name)
            .contextMenu {
                Button("Delete") { delete() }
            }
    }
    
    func delete() {
        context.delete(folder)
    }
}

