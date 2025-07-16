//
//  FilingView.swift
//  File Driver
//
//  Created by Jimmy on 6/19/25.
//

import SwiftUI
import SwiftData



struct FilingView: View {
    @AppStorage(BOF_Settings.Key.filingDrive.rawValue) var driveID : String = ""
    @State private var driveDelegate = DriveDelegate(actions: [.newFolder, .upload, .move, .rename, .trash, .filter, .preview])

    @State private var isFiling = false
   
    var body: some View {
        if driveID.isEmpty {
            DriveSelector("Select Filing Drive", canLoadFolders: false, fileID: $driveID)
        } else {
            DriveView("Shared Drive", delegate: $driveDelegate)
                .disabled(isFiling)
                .inspector(isPresented: .constant(true)) {
                    let items = driveDelegate.selection.sorted(by: {$0.title.ciCompare($1.title)})
                                                       .compactMap({FileToCase_Item($0)})
                    FileToCase(items) { isFiling in
                        self.isFiling = isFiling
                    } filed: { filedItems in
                        driveDelegate.filesWereRemoved(filedItems.compactMap({$0.file}))
                        driveDelegate.selectFirstItem()
                    }
                        .inspectorColumnWidth(min: 500, ideal: 500)
                }
                .onAppear() {
                    driveDelegate.rootID = driveID
                }
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        Button { driveDelegate.refresh()} label: {Image(systemName: "arrow.clockwise")}
                        Button("New") {  driveDelegate.showUploadSheet = true }
                    }
                }
        }
    }
}


