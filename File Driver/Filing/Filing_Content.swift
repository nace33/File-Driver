//
//  FilingView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/23/25.
//

import SwiftUI

struct Filing_Content: View {

    @AppStorage(BOF_Settings.Key.filingDrive.rawValue) var driveID : String = ""
    @State private var driveDelegate = DriveDelegate(actions: [.newFolder, .upload, .move, .rename, .trash, .filter, .preview])

    @State private var isFiling = false
    @State private var filerDelegate = Filer_Delegate( actions:Filer_Delegate.Action.inlineActions)
    
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
                        .onChange(of: filerDelegate.filingState, { _, _ in
//                            print(filerDelegate.filingState.title)
                            switch filerDelegate.filingState {
                            case .isFiling:
                                isFiling = true
                            case .filed(let items, let allFiled):
                                isFiling = false
                                processFiled(items, allFiled)
                            default:
                                isFiling = false
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
    func processFiled(_ items:[Filer_Item], _ allFiled:Bool) {
        driveDelegate.removeFiles(items.compactMap(\.file?.id))
        if allFiled {
            filerDelegate.reset(reload:false)
            if let firstFile = driveDelegate.files.first {
                driveDelegate.selection = [firstFile]
            }
        }
    }
}


//
//#Preview {
//    FilingView()
//}
