//
//  FilingDownloadItem.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/2/25.
//

import SwiftUI
import BOF_SecretSauce
import WebKit

struct FilingDownloadItem : Identifiable {
    let id  : String
    let download : WKDownload
    let delegate : Web_View.DownloadDelegate
    init(_ download:WKDownload) {
        self.id = UUID().uuidString
        self.download = download
        self.delegate = Web_View.DownloadDelegate()
    }
}


struct Inbox_Filing_DownloadItemView : View {
    let filingDownloadItem : FilingDownloadItem
    init(_ filingDownloadItem:FilingDownloadItem) {
        self.filingDownloadItem = filingDownloadItem
    }
    @State private var localURL : URL?
    @State private var error : Error?
    @State private var downloadObserver  : NSKeyValueObservation?
    @State private var progress  : Double = 0.0
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HSplitView {
            contentView
                .layoutPriority(1)
            Case_Filing_Selector()
                .frame(minWidth: 300)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Upload") { cancel() }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { cancel() }
                    }
                }
        }
            .frame(minWidth:800, minHeight:600)
    }
    
    
    @ViewBuilder var contentView   : some View {
        VStack {
            if let error {
                Text(error.localizedDescription)
            }
            else if let localURL {
                QL_View(fileURL: localURL, style: .normal)
            } else {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView("Downloading ", value:progress)
                        .task(id:filingDownloadItem.id) {
                            self.downloadObserver = filingDownloadItem.download.observe(\.progress.fractionCompleted) { download, _ in
                                self.progress = download.progress.fractionCompleted
                            }
                        }
                        .progressViewStyle(.circular)
                        .onChange(of: filingDownloadItem.delegate.status) { oldValue, newValue in
                            switch newValue {
                            case .loading(_):
                               print("Loading should not be called")
                            case .finished:
                                if let url =  filingDownloadItem.download.progress.fileURL {
                                    self.localURL = url
                                } else {
                                    self.error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Download finished, but URL was lost."])
                                }
                            case .error(let error):
                                self.error = error
                            }
                        }
                    Spacer()
                }
                Spacer()
            }
        }
            .frame(maxWidth:.infinity)
    }

    
    func cancel() {
        if let localURL {
            try? FileManager.default.trashItem(at: localURL, resultingItemURL: nil)
        }
        dismiss()
    }
}



