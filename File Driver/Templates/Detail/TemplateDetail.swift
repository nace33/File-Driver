//
//  TemplateDetail.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import SwiftUI
import BOF_SecretSauce
import WebKit

struct TemplateDetail: View {
    @Environment(TemplatesController.self) var controller
    @Binding var template : Template
    
    init(_ template: Binding<Template>) {
       _template = template
   
        self.url = template.wrappedValue.file.previewURL

        _navDelegate = State(initialValue: BOF_WebView.NavDelegate()) //ignore until called in.task because don't need loading UI on initial load
        _uiDelegate  = State(initialValue: BOF_WebView.UIDelegate()) //ignore until called in.task because don't need loading UI on initial load
    }
    
    @State private var url : URL
    @State private var navDelegate : BOF_WebView.NavDelegate
    @State private var uiDelegate  : BOF_WebView.UIDelegate
    @State private var isLoading = false
    @State private var webView : WKWebView?
    @State private var mode : Mode = .preview
    @State private var showEditSheet      = false
    @State private var showAddToCaseSheet = false

    @Environment(\.openWindow) var openWindow
    @Environment(\.openURL) var openURL
    @Environment(BOF_Nav.self) var navModel

    
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
                    ProgressView("Loading \(template.title)")
                    Rectangle()
                        .fill(.gray)
                        .opacity(0.5)
                }
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $showEditSheet, content: {
                if let index = controller.index(of: template) {
                    EditTemplate(Bindable(controller).templates[index])
                } else {
                    Button("Ooopsies!") { showEditSheet.toggle() }.padding(100)
                }
            })
            .sheet(isPresented: $showAddToCaseSheet) {
                FilingSheet(showPreview: false, modes: [.cases], items: [Filer_Item(file: template.file, action: .copy)], actions:Filer_Delegate.Action.altSheetActs) { state in
                    switch state {
                    case .filed(let items, _):
                        if let first = items.first, let casesItem = BOF_SwiftData.shared.fetchFirstSidebarItem(with: .cases) {
                            navModel.sidebar = casesItem.id
                            navModel.caseID  = first.filedToCase?.id
                            if let id = first.filedToCase?.id {
                                navModel.path.append(id)
                            }
                        }
                    default:
                        break
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    switch mode {
                    case .preview:
                        Menu("Edit") {
                            Button("Document") { mode = .edit}
                            Button("Template Data") { showEditSheet.toggle() }
                        }
                    case .edit:
                        Button("Done") { mode = .preview}
                    }
  
                    Button("Add To Case") { showAddToCaseSheet.toggle() }

                }
            }
            .onChange(of: mode, { _, _ in  updateWebView()  })
            .task(id:template.id) { updateWebView() }
    }
  
    func updateWebView() {
        switch mode {
         case .preview:
             self.url = template.file.previewURL
         case .edit:
             self.url = template.file.editURL
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
//                if let url = download.progress.fileURL {
//                    NSWorkspace.shared.open(url)
//                }
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

