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
    
    @State private var delegate     = Web_View.Delegate()
    @State private var fileItem     : Filer_Item? = nil
    
    var body: some View {
        Web_View(url, delegate: delegate)
            .task(id:url)                     {  updateWebView() }
            .sheet(item: $fileItem)    { item in
                FilingSheet(items:[item])
                    .frame(minWidth: 800, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
            }
    }

    
    
    func updateWebView() {
        self.delegate =  Web_View.Delegate { url, webView in
            guard !url.absoluteString.contains("mail/u/0/popout?") else { return false }
            guard !url.absoluteString.contains("https://www.google.com/url?q=") else {
                File_DriverApp.createWebViewTab(url: url, title:webView.title ?? "File Driver 2.0")
                return false
            }
            guard url.queryItemValue(queries: ["view"]) != "pt" else {
                self.fileItem = Filer_Item(url: url, filename:  webView.title ?? "Email", category: .remotePDFURL)

                return false
            }
            return true//allow webview to load: loadClickedURL
        } downloadPolicy: { navigation in
            if Web_View.Delegate.isStandardDownload(navigation) {
                if let url = navigation.response.url {
                    self.fileItem = Filer_Item(url: url, filename:navigation.response.suggestedFilename ?? "Attachment", category: .remoteURL)
                }
                return .cancel
            }
            return .allow
        }

    }
}


