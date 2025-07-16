//
//  FilingSheet.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/9/25.
//

import SwiftUI
import BOF_SecretSauce
import GoogleAPIClientForREST_Drive


struct FilingSheet: View {
    var urlItems  : [FileToCase_URLItem]
    var fileItems : [FileToCase_Item]
    @State private var readyToFileItems : [FileToCase_Item] = []
    @State private var loader = VLoader_Item()
    @State private var selectedItem : FileToCase_URLItem = .init(url:URL(string:"about:blank")!, filename:"Empty", category: .remotePDFURL)
    @State private var selectedFolder : GTLRDrive_File? = nil
    @Environment(\.dismiss) var dismiss
    @AppStorage(BOF_Settings.Key.filingAutoRename.rawValue)  var automaticallyRenameFiles: Bool = true
    @AppStorage(BOF_Settings.Key.filingDrive.rawValue)       var driveID : String = ""
//    @AppStorage("BOF_Filing_SaveToLocation")
    @State private var saveTo : SaveTo = .caseSpreadsheet
    @AppStorage(BOF_Settings.Key.filingAutoRenameBlockedWords.rawValue)           var blockedRenameWords     : [String] = ["Nasser Law Firm Mail - "]
    enum SaveTo : String, CaseIterable, Codable {
        case caseSpreadsheet = "Save to a NLF Case"
        case customFolder    = "Save To a Drive Folder"
    }
    @State private var driveDelegate = DriveDelegate(actions: [.newFolder], mimeTypes: [.folder])
    
    var body: some View {
        VStackLoacker(loader: $loader) {
            cancel()
        } content: {
            HSplitView {
                preview()
                    .frame(minWidth:200)
                Group {
                    switch saveTo {
                    case .caseSpreadsheet:
                        FileToCase(readyToFileItems, actions: [.fileLater, .cancel, .addToCase]) { isFiling in
                            //                    self.isFiling = isFiling
                        } filed: { filedItems in
                            //                    justFiled($0)
                        } canceled: {
                            cancel()
                        }
                    case .customFolder:
                        DriveView(delegate: $driveDelegate)
                            .onChange(of: driveDelegate.selection) { oldValue, newValue in
                                selectedFolder = newValue.count == 0 || newValue.count > 1 ? nil : newValue.first
                            }
                    }
                }
                    .frame(minWidth:400)
                    .onChange(of: saveTo) { oldValue, newValue in
                        selectedFolder = nil
                    }
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { reloadReadyToLoadItems() }
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    if driveID.count > 0 {
                        Button("File Later") { Task{ await saveTo(driveID)} }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }
                ToolbarItem(placement: .primaryAction) {
                    switch saveTo {
                    case .caseSpreadsheet:
                        Button("Add To Case") { }
                            .disabled(loader.isLoading)
                    case .customFolder:
                        Button("Upload") {Task{ await saveTo(selectedFolder!.id)}  }
                            .disabled(selectedFolder == nil )
                    }
                }
            }
    }
}

//MARK: - Propertes
fileprivate extension FilingSheet {
    var showInspector : Bool {
        guard !loader.isLoading else { return false }
        return urlItems.allSatisfy { $0.category == .localURL}
    }
}

//MARK: - Actions
fileprivate extension FilingSheet {
    func reloadReadyToLoadItems() {
        selectedItem = .init(url:URL(string:"about:blank")!, filename:"Empty", category: .remotePDFURL)
        readyToFileItems.removeAll()
        Task { await download() }
    }
    func download() async {
        do {
            loader.isLoading = true
            for item in self.urlItems {
                loader.status = "Downloading \(item.filename)"
                switch item.category {
                case .driveFile, .localURL:
                    continue
                case .remoteURL:
                    if let remoteURL = item.remoteURL {
                        let url  = try await URLSession.download(remoteURL, to: URL.downloadsDirectory) { loader.progress = $0  }
                        processDownload(of:url, for: item)
                    }
                case .remotePDFURL:
                    if let remoteURL = item.remoteURL {
                        let url = try await WebViewToPDF.print(url:remoteURL, saveTo: URL.downloadsDirectory) {  loader.progress = $0 }
                        processDownload(of:url, for: item)
                    }
                }
            }
            loader.isLoading = false
        } catch {
            loader.error = error
            loader.isLoading = false
        }
    }
    func processDownload(of url:URL, for item:FileToCase_URLItem) {
        let emailThread = url.emailThread
        if automaticallyRenameFiles,
           let renamedURL = try? AutoFile_Rename.autoRenameLocalFile(url: url, thread:emailThread, blockWords: blockedRenameWords) {
            item.localURL = renamedURL
        } else {
            item.localURL = url
        }
        item.category = .localURL
        item.emailThread = emailThread
        item.status = .readyToFile
        item.filename = item.localURL!.deletingPathExtension().lastPathComponent
        
        if selectedItem.filename == "Empty" {
            selectedItem = item
        }
    }

    func saveTo(_ destinationID:String) async {
        do {
            loader.isLoading = true
            for item in urlItems.filter({ $0.status == .readyToFile }) {
                if let localURL = item.localURL {
                    loader.status = "Uploading \(item.filename)"
                    let appProp = item.emailThread?.driveAppProperties
                    _ = try await Drive.shared.upload(url:localURL, filename:item.filename, to:destinationID, appProperties:appProp) { progress in
                        loader.progress = progress
                    }
                    item.status = .filed
                }
            }
            loader.isLoading = false
        } catch {
            loader.isLoading = false
            loader.error = error
        }

        cancel()
        loader.isLoading = true
    }
    func trashLocalFiles(_ items:[FileToCase_URLItem]) {
        for i in urlItems {
            if let localURL = i.localURL {
                try? FileManager.default.trashItem(at:localURL, resultingItemURL: nil)
            }
        }
    }
    func cancel() {
        trashLocalFiles(urlItems)
        dismiss()
    }
}


//MARK: - View Builders
fileprivate extension FilingSheet {
    @ViewBuilder func preview() -> some View {
        VStack {
            previewTitleHeader
            preview(selectedItem)
        }
    }
    @ViewBuilder var previewHeader : some View {
        HStack {
            Picker("Save To", selection:$saveTo) {
                ForEach(SaveTo.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
                .pickerStyle(.segmented)
                .fixedSize()
        }
        .padding(10)
    }
    @ViewBuilder var previewTitleHeader : some View {
        HStack {
            Menu(selectedItem.filename) {
                ForEach(urlItems, id:\.self) { item in
                    Button(item.filename) { selectedItem = item }
                }
                if urlItems.count > 0 {
                    Divider()
                }
                switch saveTo {
                case .caseSpreadsheet:
                    Button("Drive Folder") { saveTo = .customFolder }
                case .customFolder:
                    Button("Case") { saveTo = .caseSpreadsheet }
                }
                Divider()

                Button("Cancel") { cancel() }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(urlItems.count == 1 ? .hidden : .visible)
        }
        .padding(10)
    }
    @ViewBuilder func preview(_ item:FileToCase_URLItem) -> some View {
        if item.category == .localURL, let localURL = item.localURL {
            QL_View(fileURL:localURL, style: .normal)
        } else {
            ProgressView("Downloading \(item.filename)")
        }

    }
}

