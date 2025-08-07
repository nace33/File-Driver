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
    @State private var temp     : TempItem? = nil
    
    struct TempItem : Identifiable {
        let id = UUID().uuidString
        let fileItem : Filer_Item
        let aCase    : Case
    }
    
    var body: some View {
        Web_View(url, delegate: delegate)
            .task(id:url)                     {  updateWebView() }
            .sheet(item: $fileItem)    { item in
                FilingSheet(items:[item])
            }
    }


    func tester(url:URL, title:String) async {
        if let file = try? await Drive.shared.get(fileID: "1DUl2df2QNPdheJyX4Cg41jT16sTa4kfMjiA45QR97BI", labelIDs: [Case.DriveLabel.Label.id.rawValue]),
           let aCase = Case(file) {
            self.temp     = .init(fileItem: Filer_Item(url: url, filename:title, category: .remotePDFURL), aCase: aCase)
        }
    }
    
    func updateWebView() {
        self.delegate =  Web_View.Delegate { url, webView in
            guard !url.absoluteString.contains("mail/u/0/popout?") else { return false }
            guard !url.absoluteString.contains("https://www.google.com/url?q=") else {
                #if os(macOS)
                File_DriverApp.createWebViewTab(url: url, title:webView.title ?? "File Driver 2.0")
                #endif
                return false
            }
            guard url.queryItemValue(queries: ["view"]) != "pt" else {
//                Task { await tester(url:url, title:webView.title ?? "Email")}
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


