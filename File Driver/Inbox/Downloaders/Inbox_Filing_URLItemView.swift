//
//  Inbox.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/2/25.
//

import SwiftUI
import BOF_SecretSauce
import WebKit
import GoogleAPIClientForREST_Drive
import PDFKit

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
    
    @AppStorage(BOF_Settings.Key.filingDrive.rawValue)       var driveID : String = ""
    @AppStorage(BOF_Settings.Key.filingAutoRename.rawValue)  var automaticallyRenameFiles: Bool = true

    @State private var isUploading = false
    @State private var gmailThread : PDFGmailThread?
    
    var caseSuggestions : [String] {[
        frodoFolder
    ]}
    let frodoFolder = "14baQMC2vUIa8HUxF6ca3DyRstS7QT8yE"
    let frodoCase   = "1-iNgaNY8VcHgDCD66KoupqbnsJjv7oZ6WHw8hTpG1AE"
    var body: some View {
        HSplitView {
            contentView
                .layoutPriority(1)
            Group {
                if isUploading {
                    VStack {
                        Spacer()
                        ProgressView("Uploading", value: progress)
                            .padding(.horizontal)
                        Spacer()
                    }
                } else {
                    CaseSelector(caseSuggestions, header: {
                        Text("Butts")
                    }, content: { aCase, destination, stack in
                        Text("Huh")
                    })
                }
            }
                .frame(minWidth: 300)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("File Later") { Task { await fileLater() }  }
                            .disabled(driveID.isEmpty)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { cancel() }
                    }
                }
        }
            .frame(minWidth:800, minHeight:600)
            .disabled(isUploading)

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

    
    // download URL
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
                await loadGmailThread()
                await renameLocalFile()
            }
        } catch {
            self.error = error
        }
    }
    
    //load downloaded URL's metadata
    func loadGmailThread() async  {
        guard let localURL else { return }
        self.gmailThread = localURL.pdfGmailThread
    }
    func renameLocalFile() async {
        guard let renamedURL = try? AutoFile_Rename.autoRenameLocalFile(url: localURL, thread:gmailThread) else { return }
        self.localURL = renamedURL
    }
    
    //File Later
    func fileLater() async {
        guard let localURL else { return }
        do {
            isUploading = true
            var wordString : String? = nil
            if let gmailThread {
                print("Do something with the thread: \(gmailThread)")
//                wordString = gmailThread.words(for:[.contacts, .attachments], fullStrings: true).joined(separator: " ")
                if wordString == " " {
                    wordString = nil
                }
            }
            _ = try await Drive.shared.upload(url:localURL, to: driveID, description: wordString) { progress in
                self.progress = progress
            }
            dismiss()
        } catch {
            print("Error: \(error.localizedDescription)")
            isUploading = false
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

