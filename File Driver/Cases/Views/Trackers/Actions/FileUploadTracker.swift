//
//  Case.TrackersView_FileUpload.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/5/25.
//

import SwiftUI

struct FileUploadTracker: View {
    @Environment(TrackerDelegate.self) var trackerDelegate
    init(aCase:Case) {
        _filerDelegate = State(initialValue: .init(modes: [.aCase(aCase)], actions: [.newFolder, .cancel]))
    }
    @State private var filerDelegate : Filer_Delegate
    @State private var showFileImport : Bool = true
    @State private var uploadItem : FilerSheetItem? = nil
    @Environment(\.dismiss) var dismiss

    
    var body: some View {
        FilingSheet(delegate: filerDelegate, items:uploadItem?.items ?? []) { state in
            switch state {
            case .formPresented:
                if let root = trackerDelegate.selectedRoot {
                    filerDelegate.trackers = [Case.Tracker.init(root: root.wrappedValue)]
                }
            case .caseUpdated(_):
                //Case was already updated, just update Tracker Roots
                if let root = trackerDelegate.selectedRoot {
                    trackerDelegate.rebuild(threadID: root.wrappedValue.threadID)
                }
            default:
                break
            }
        }
            .fileImporter(isPresented:$showFileImport, allowedContentTypes: DriveDelegate.urlTypes, allowsMultipleSelection:true) { result in
                switch result {
                case .success(let urls):
                    uploadItem = FilerSheetItem(urls: urls)
                case .failure(_):
                    uploadItem = nil
                }
            }
            .onChange(of: showFileImport) { oldValue, newValue in
                if !showFileImport, uploadItem == nil { dismiss() }
            }
    }
}
