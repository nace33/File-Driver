//
//  FilingView.swift
//  File Driver
//
//  Created by Jimmy on 6/19/25.
//

import SwiftUI

struct FilingView: View {
    @Environment(FilingController.self) var controller
    @AppStorage(BOF_Settings.Key.filingDrive.rawValue) var driveID : String = ""
    @State private var driveDelegate = Google_DriveDelegate(actions: [.upload, .delete])
    
    
    var body: some View {
        if driveID.isEmpty {
            Google_DriveSelector("Select Filing Drive", canLoadFolders: false, fileID: $driveID)
        } else {
            HSplitView {
                Google_DriveView(delegate: $driveDelegate, header:{ })
                    .onAppear() {   driveDelegate.rootID = driveID }
                    .frame(minWidth:400, idealWidth: 400, maxWidth: 400)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigation) {
                            Button { driveDelegate.refresh()} label: {Image(systemName: "arrow.clockwise")}
                            Button("Add") {  driveDelegate.showUploadSheet = true }
                        }
                    }
                Group {
                    if let selectedFile = driveDelegate.selected {
                        CaseSelector() {
                            Button("Add To Case") { }
                                .buttonStyle(.borderedProminent)
                        } content: { aCase, folder, stack in
                            Form {
                                Text(aCase.title)
                                ForEach(stack) { f in
                                    Text(f.title)
                                }
                                Text(folder.title)
                            }
                        }
                    } else {
                        ContentUnavailableView("No Selection", systemImage: "filemenu.and.selection", description: Text("Select a file from the list on the left."))
                    }
                }
                .layoutPriority(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}


