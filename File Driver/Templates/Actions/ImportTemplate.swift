//
//  ImportTemplate.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct ImportTemplate: View {
    @State private var selected : GTLRDrive_File?
    @AppStorage(BOF_Settings.Key.templateDriveID.rawValue)  var driveID : String = ""

    var body: some View {
        if driveID.isEmpty {
            DriveSelector("Select a Default Template Drive", showCancelButton: true, canLoadFolders: false, mimeTypes: [.folder]) { self.driveID = $0.id; return false }
        }
        else if let selected {
            if selected.driveId == driveID {
                NewTemplate(from: selected) 
            } else {
                DuplicateTemplate(.init(copyFile: selected)) {
                    Button { self.selected = nil } label: {Image(systemName: "chevron.left")}
                    Text("Import Template").font(.title2)
                }
            }
        } else {
            DriveSelector("Shared Drives", showCancelButton: true, canLoadFolders: true, mimeTypes: GTLRDrive_File.MimeType.googleTypes + [.pdf]) { selected in
                self.selected = selected
                return false //presents sheet from being dismissed
            }
        }
    }
}

#Preview {
    ImportTemplate()
        .environment(TemplatesDelegate.shared)
}

