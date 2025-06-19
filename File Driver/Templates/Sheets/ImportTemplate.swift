//
//  ImportTemplate.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct ImportTemplate: View {
    @Environment(TemplatesController.self) var controller
    @Environment(\.dismiss) var dismiss
    @State private var selected : GTLRDrive_File?
    @AppStorage(BOF_Settings.Key.templateDriveID.rawValue)        var driveID       : String = ""

    var body: some View {
        if let selected {
            DuplicateTemplate(.init(copyFile: selected)) {
                Button { self.selected = nil } label: {Image(systemName: "chevron.left")}
                Text("Import Template").font(.title2)
            }
        } else {
            Text("Drive Navigator Here")
//
//            Drive_Selector(rootTitle: "Shared Drives", rootID: nil, mimeTypes: [.doc, .pdf, .sheet], labelIds: [Template.DriveLabel.id.rawValue], row: { file in
//                let hasLabel = file.label(id: Template.DriveLabel.id.rawValue) != nil
//                HStack {
//                    Label { Text(file.title) } icon: { file.icon }
//                    if hasLabel {
//                        Image(systemName: "checkmark.circle.fill")
//                            .foregroundStyle(.green)
//                    }
//                }
//                    .selectionDisabled(hasLabel)
//            }, select: { file in
//                selected = file
//            })
//            .frame(height:265)
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Cancel") { dismiss() }
//                }
//                ToolbarItem(placement: .primaryAction) {
//                    Button("Create") { }
//                        .disabled(true)
//                }
//            }
        }
    }
}

#Preview {
    ImportTemplate()
}
