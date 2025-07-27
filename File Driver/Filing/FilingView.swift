//
//  FilingView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/23/25.
//

import SwiftUI

struct FilingView: View {

    @AppStorage(BOF_Settings.Key.filingDrive.rawValue) var driveID : String = ""
    @State private var driveDelegate = DriveDelegate(actions: [.newFolder, .upload, .move, .rename, .trash, .filter, .preview])

    @State private var isFiling = false
    @State private var filerDelegate = Filer_Delegate(mode: .cases, actions:Filer_Delegate.Action.inlineActions)
    
    var body: some View {
        if driveID.isEmpty {
            DriveSelector("Select Filing Drive", canLoadFolders: false, fileID: $driveID)
        } else {
            DriveView("Shared Drive", delegate: $driveDelegate)
                .disabled(isFiling)
                .inspector(isPresented: .constant(true)) {
                    
                    Filer_View(items: [], delegate: filerDelegate)
                        .onChange(of: driveDelegate.selection, { _, _ in
                            Task {
                                let items = driveDelegate.selection
                                                         .sorted(by: {$0.title.ciCompare($1.title)})
                                                         .compactMap({Filer_Item(file:$0)})
                                filerDelegate.items = items
                            }
                        })
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


//
//#Preview {
//    FilingView()
//}
