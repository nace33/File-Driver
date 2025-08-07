//
//  Filing_Preview.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/23/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce
import WebKit

struct DriveFileView: View {
    let files : [GTLRDrive_File]
    @State private var selectedFile : GTLRDrive_File?
    @State private var navDelegate : BOF_WebView.NavDelegate
    @State private var uiDelegate  : BOF_WebView.UIDelegate
    @State private var isLoading : Bool
    @State private var webView : WKWebView?
    init(_ files: [GTLRDrive_File], isLoading:Bool = true) {
        self.files = files
        _navDelegate = State(initialValue: BOF_WebView.NavDelegate()) //ignore until called in.task because don't need loading UI on initial load
        _uiDelegate  = State(initialValue: BOF_WebView.UIDelegate()) //ignore until called in.task because don't need loading UI on initial load
        _isLoading   = State(initialValue: isLoading)
    }
    
    
    
    var body: some View {
        VStack(alignment: .leading, spacing:0) {
            if files.count > 1 {
                header
                    .disabled(isLoading)
            }
            ZStack {
                if let selectedFile {
                    BOF_WebView(selectedFile.previewURL, navDelegate: navDelegate, uiDelegate: uiDelegate)
                        .opacity(isLoading ? 0.25 : 1)
                }
                else {
                    ContentUnavailableView("File Preview", systemImage: "filemenu.and.selection", description: Text("Select a file to show a preview."))
                }
                if isLoading {
                    Rectangle()
                        .fill(.black)
                    ProgressView("Loading Preview")
                    Rectangle()
                        .fill(.gray)
                        .opacity(0.5)
                }
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task(id:files) { updateWebView() }
    }

}

//MARK: - WebView
fileprivate extension DriveFileView {
    func updateWebView() {
        selectedFile = files.first
   
        self.navDelegate = BOF_WebView.NavDelegate { status, webView in
            self.webView = webView
            switch status {
            case .loading:
                self.isLoading = true
//                print("Progress: \(progress)")
            case .finished:
                self.isLoading = false
//                webView.evaluateJavaScript("document.documentElement.scrollHeight", completionHandler: { (height, error) in
//                    print("height \(height)")
//                    print(height)
//                    webView.bounds.size.height = height as! CGFloat
//                })
            case .error:
                self.isLoading = false
            }
        } download: { status, download in
            switch status {
            case .downloading:
                print("Downloading")
            case .completed:
                if let url = download.progress.fileURL {
                    NSWorkspace.shared.open(url)
                }
                print("Download: \(String(describing: download.progress.fileURL))")
            case .failed:
                print("Unable to download")
            }
        }
        
        self.uiDelegate = BOF_WebView.UIDelegate { url, _ in
//            print("URL: \(url)")
            return false//do NOT allow any links to all to load
        }
    }
}



//MARK: - Selection
fileprivate extension DriveFileView {
    var selectedIndex: Int? {
        files.firstIndex(where: {$0.id == selectedFile?.id}) ?? nil
    }
    var canSelectPrevious : Bool {
        guard files.count > 1 else { return false }
        guard let index = selectedIndex else { return false }
        return index > 0
    }
    func selectPrevious() {
        guard canSelectPrevious else { return }
        guard let index = selectedIndex else { return }
        selectedFile = files[index-1]
    }
    var canSelectNext : Bool {
        guard files.count > 1 else { return false }
        guard let index = selectedIndex else { return false }
        return index < files.count - 1
    }
    func selectNext() {
        guard canSelectNext else { return }
        guard let index = selectedIndex else { return }
        selectedFile = files[index+1]
    }
    
    @ViewBuilder var header : some View {
        
        HStack {
            selectPreviousButton
            Spacer()
            titleMenu
            Spacer()
            selectNextButton
        }
            .padding(8)
            .background(.background)
            .buttonStyle(.plain)
    }
    @ViewBuilder var titlePicker : some View {
        Picker("File", selection: $selectedFile) {
            ForEach(files, id:\.self) { file in
                Text(file.title).tag(file)
            }
        } currentValueLabel: {
            Text(selectedFile?.title ?? "No Selection")
        }
            .labelsHidden()
            .fixedSize()
            .menuStyle(.borderlessButton)
       
    }
    @ViewBuilder var titleMenu : some View {
        Menu(selectedFile?.title ?? "No Selection") {
            ForEach(files, id:\.self) { file in
                if file == selectedFile {
                    Button(file.title, systemImage: "checkmark") {
                        selectedFile = file
                    }
                } else {
                    Button(file.title) { selectedFile = file }
                }
            }
        }
        .fixedSize()
        .menuStyle(.borderlessButton)
    }
    @ViewBuilder var selectPreviousButton: some View {
        Button { selectPrevious() } label: {
            Image(systemName: "chevron.left")
        }.disabled(!canSelectPrevious)
    }
    @ViewBuilder var selectNextButton: some View {
        Button {selectNext() } label: {
            Image(systemName: "chevron.right")
        }.disabled(!canSelectNext)
    }
}
