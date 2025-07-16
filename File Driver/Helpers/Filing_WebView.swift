//
//  Filing.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//
import BOF_SecretSauce
import SwiftUI
import WebKit

struct Filing_WebView: View {
    let url : URL
    init(_ url:URL ) {
        self.url = url
     
    }
    
    @State private var webView      : WKWebView?
    @State private var delegate     = Web_View.Delegate()
    @State private var fileItem     : FileToCase_URLItem? = nil

    var body: some View {
        Web_View(url, delegate: delegate)
            .task(id:url)                     {  updateWebView() }
            .sheet(item: $fileItem)    {
                FilingSheet(urlItems:[$0], fileItems:[])
                    .frame(minWidth: 600, minHeight: 400)
            }
            .toolbar {
                Button("Create PDF ") { createPDF() }
            }
    }



    func createPDF() {
        guard let webView, let url = webView.url else {  return   }
        self.fileItem = FileToCase_URLItem(url: url, filename:  webView.title ?? "Download", category: .remotePDFURL)
    }
    
    
    func updateWebView() {
        self.delegate = Web_View.Delegate(clicked: { url, webView in
            self.webView = webView
            return true//allow webview to load: loadClickedURL
        }, downloadPolicy: { navigation in
            if Web_View.Delegate.isStandardDownload(navigation) {
                if let url = navigation.response.url {
                    self.fileItem = FileToCase_URLItem(url: url, filename:navigation.response.suggestedFilename ?? "Download", category: .remoteURL)
                }
                return .cancel
            }
            return .allow
        })
    }
}




