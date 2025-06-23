//
//  Google.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/17/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

struct Google_DriveView_RowLabel : View {
    @Environment(Google_DriveDelegate.self) var delegate
    let file : Binding<GTLRDrive_File>
    init(_ file: Binding<GTLRDrive_File>) {
        self.file = file
    }

    var body: some View {
        if let item = delegate.uploadItems.first(where: {$0.id == file.wrappedValue.id}) {
            Label {
                Text(file.wrappedValue.name ?? "No Filename" )
                    .foregroundStyle(.secondary)
            } icon: {
                CircularProgressView(progress:Double(item.progress))

            }
                .selectionDisabled(true)
        }
        else if let item = delegate.downloadItems.first(where: {$0.id == file.wrappedValue.id}) {
            Label {
                Text(file.wrappedValue.name ?? "No Filename" )
            } icon: {
                CircularProgressView(progress:Double(item.progress))
            }
        }
        else if delegate.moveItemIDs.contains(file.id) {
            Label {
                Text(file.wrappedValue.name ?? "No Filename" )
                    .foregroundStyle(.secondary)
            } icon: {
                CircularProgressView()
            }
                .selectionDisabled(true)
        }
        else {
            Label {
                Text(file.wrappedValue.name ?? "No Filename" )
            } icon: {
                Image(file.wrappedValue.mime.title)
                    .resizable()
                    .scaledToFit()
            }
//            Moved to Google_DriveView.body so multiple selected items can have context menu
//                .if(delegate.actions.isNotEmpty) { content in
//                    content
//                        .contextMenu {
//                            Google_DriveView_HeaderActionButtons(file: file.wrappedValue, style: .text)
//                        }
//                }
        }
    }
}

