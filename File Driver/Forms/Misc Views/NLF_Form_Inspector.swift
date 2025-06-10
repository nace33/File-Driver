//
//  NLF.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/27/25.
//

import SwiftUI
import BOF_SecretSauce
import WebKit

struct NLF_Form_Inspector : View {
    var form : NLF_Form
    init(form: NLF_Form) {
        self.form = form
   

        if let string = UserDefaults.standard.value(forKey: BOF_Settings.Key.formViewModeKey.rawValue) as? String,
           let modeType =  Mode(rawValue:string) {
            switch modeType {
            case .preview:
                self.url = form.file.previewURL
            case .edit:
                self.url = form.file.editURL
            }
        } else {
            self.url = form.file.previewURL
        }
        _navDelegate = State(initialValue: BOF_WebView.NavDelegate()) //ignore until called in.task because don't need loading UI on initial load
        _uiDelegate  = State(initialValue: BOF_WebView.UIDelegate()) //ignore until called in.task because don't need loading UI on initial load
    }
    
    @State private var url : URL
    @Environment(NFL_FormController.self)  var controller
    @AppStorage(BOF_Settings.Key.formViewModeKey.rawValue)  var mode  : Mode      = .preview
    @AppStorage(BOF_Settings.Key.formsShowExamplesKey.rawValue)  var showExamples  = false
    
    @State private var navDelegate : BOF_WebView.NavDelegate
    @State private var uiDelegate  : BOF_WebView.UIDelegate
    @State private var isLoading = false
    @State private var webView : WKWebView?
    
    enum Mode : String, CaseIterable, Codable {
        case preview
        case edit
    }

    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                BOF_WebView(url, navDelegate: navDelegate, uiDelegate: uiDelegate)
                    .opacity(isLoading ? 0.25 : 1)
                if isLoading {
                    Rectangle()
                        .fill(.black)
                    ProgressView("Loading \(form.title)")
                    Rectangle()
                        .fill(.gray)
                        .opacity(0.5)
                }
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Picker("Mode", selection: $mode) { ForEach(Mode.allCases, id:\.self) { Text($0.rawValue.capitalized)}}
                        .pickerStyle(SegmentedPickerStyle())
                        .fixedSize()
                        .labelsHidden()
      
                }             
            }
            .onChange(of: mode, { _, _ in  updateWebView()  })
            .task(id:form.id) { updateWebView() }
        
    }

    
    func updateWebView() {
        switch mode {
         case .preview:
             self.url = form.file.previewURL
         case .edit:
             self.url = form.file.editURL
         }
   
        self.navDelegate = BOF_WebView.NavDelegate { status, webView in
            self.webView = webView
            switch status {
            case .loading:
                self.isLoading = true
//                print("Progress: \(progress)")
            case .finished:
                self.isLoading = false
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
            return true//allow all to load
        }
    }
}
