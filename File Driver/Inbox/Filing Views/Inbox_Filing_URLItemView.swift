//
//  Inbox.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/2/25.
//

import SwiftUI
import BOF_SecretSauce
import WebKit

struct FilingURLItem: Identifiable {
    let id  : String
    let url : URL
    init(_ url:URL) {
        self.id = UUID().uuidString
        self.url = url
    }
}

struct Inbox_Filing_URLItemView : View {
    let filingURLItem : FilingURLItem
    init(_ filingURLItem:FilingURLItem) {
        self.filingURLItem = filingURLItem
    }
    @State private var localURL : URL?
    @State private var error : Error?
    @Environment(\.dismiss) var dismiss
    
    //Progress
    @State private var urlObservation: NSKeyValueObservation?
    @State private var progress : Double = 0.0
    
    
    
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
    
    
    
    //View Builders
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
                    ProgressView("Downloading", value: progress)
                        .progressViewStyle(.circular)
                    Spacer()
                }
                    .task {
                       await loadLocalFile()
                    }
                Spacer()
                
            }
        }
            .frame(maxWidth:.infinity)
    }
    @ViewBuilder var inspectorView : some View {
        VStack {
            Spacer()
            Text("Inspector View ...")
                .frame(maxWidth:.infinity, alignment: .center)
            Button("Cancel") {   cancel()}
            Spacer()
        }
        .frame(width:300)
    }
    
    
    // Call
    func loadLocalFile() async  {
        do {
            if filingURLItem.url.isFileURL {
                self.localURL = filingURLItem.url
            } else {
                self.localURL = try await WebViewToPDF.print(url:filingURLItem.url, saveTo: URL.downloadsDirectory) { webView in
                    urlObservation = webView.observe(\.estimatedProgress) { webViewProgress, _ in
                        self.progress = webViewProgress.estimatedProgress
                    }
                }
            }
        } catch {
            self.error = error
        }
    }
    func cancel() {
        if let localURL {
            try? FileManager.default.trashItem(at: localURL, resultingItemURL: nil)
        }
        dismiss()
    }
}

