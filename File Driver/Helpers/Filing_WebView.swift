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
    
    @State private var delegate  = Web_View.Delegate()

    @State private var filingURLItem      : FilingURLItem?
    @State private var filingDownloadItem : FilingDownloadItem?
    @State private var webView : WKWebView?
    
    var body: some View {
        Web_View(url, delegate: Web_View.Delegate(downloadDirectory: URL.downloadsDirectory, loading: { status, webView in
                self.webView = webView
        }, downloadDelegate: { download in
            self.filingDownloadItem = FilingDownloadItem(download)
            return self.filingDownloadItem!.delegate
        }))
            .sheet(item: $filingURLItem)      {  Inbox_Filing_URLItemView($0)  }
            .sheet(item: $filingDownloadItem) {  Inbox_Filing_DownloadItemView($0)}
            .toolbar {
                Button("Create PDF ") { createPDF() }
            }
    }



    func createPDF() {
        guard let webView, let url = webView.url else {  return   }
        self.filingURLItem = FilingURLItem(url)
    }
}
