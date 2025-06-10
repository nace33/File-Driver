//
//  Inbox_View.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/31/25.
//

import SwiftUI
import WebKit
import BOF_SecretSauce



struct Inbox_View: View {
    let url : URL
    init(url:URL = URL(string: "https://mail.google.com")!) {
        self.url = url
    }
    
    @State private var delegate  = Web_View.Delegate()

    @State private var filingURLItem      : FilingURLItem?
    @State private var filingDownloadItem : FilingDownloadItem?
    
    var body: some View {
        Web_View(url, delegate: delegate)
            .task(id:url)                     {  updateWebView() }
            .sheet(item: $filingURLItem)      {  Inbox_Filing_URLItemView($0)  }
            .sheet(item: $filingDownloadItem) {  Inbox_Filing_DownloadItemView($0)}
    }

    
    
    func updateWebView() {
        self.delegate = Web_View.Delegate(clicked: { url, webView in
            guard !url.absoluteString.contains("mail/u/0/popout?") else { return false }
            guard !url.absoluteString.contains("https://www.google.com/url?q=") else {
                File_DriverApp.createWebViewTab(url: url, title:webView.title ?? "File Driver 2.0")
                return false
            }
            guard url.queryItemValue(queries: ["view"]) != "pt" else {
                self.filingURLItem = FilingURLItem(url)
                return false
            }
            return true//allow webview to load: loadClickedURL
        }, downloadDelegate: { download in
            self.filingDownloadItem = FilingDownloadItem(download)
            return self.filingDownloadItem!.delegate
        })
    }
}


