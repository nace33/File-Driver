//
//  Inbox_View.swift
//  Nasser Law Firm
//
//  Created by Jimmy Nasser on 3/11/25.
//

import SwiftUI
import WebKit
import BOF_SecretSauce
/*

import PDFKit
struct Inbox_View_Old: View {
    var websiteURL : URL
    var userAgent : String
//    @State private var uploadItem : Upload_Item?
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage(BOF_Settings.Key.inboxImmediateFilingKey.rawValue)  var immediateFiling: Bool = false

    init(websiteURL: URL, userAgent: String? = nil) {
        self.websiteURL = websiteURL
        self.userAgent = userAgent ?? "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_7_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Safari/605.1.15"
    }
    @State private var isSavingLinksForLater = false
    
    var body: some View {
        Web_View(request: URLRequest(url:websiteURL), userAgent: userAgent, mode:.single, clicked:  { url, webView in
            process(url: url, webView: webView)
        })
            .sheet(isPresented: $isSavingLinksForLater) {
                VStack {
                    Text("Saving to Filing Items...")
                        .font(.title)
                    AnimatedCheckmarkView(size: .init(width: 100, height: 100))
                }
                    .padding()
            }
//            .sheet(item:$uploadItem) { item in
//                Upload_Item_New(item: item)
//            }
    }
}


//MARK: WebView
extension Inbox_View_Old {
    @MainActor
//    func downloadLater(_ item:Upload_Item) async {
//        isSavingLinksForLater = true
//        try? await Task.sleep(for: .seconds(2.0))
//        modelContext.insert(item)
//        isSavingLinksForLater = false
//    }
    private func process(url:URL, webView:WKWebView) -> Bool {//false means do not intercept url
        //        print("***Process: \(url)")
        //Do not allow popout navigations
//        print("URL: \(url)")
        guard !url.absoluteString.contains("mail/u/0/popout?") else { return false }
        //ignore URLs while processing the action
//        guard uploadItem == nil else { return false }
        //determine if url has pt or att, which indicates user is attempting to download or print
        
        //Check for print or download commands
        let foundPrint = if let v = url.queryItemValue(queries: ["print"]), v == "true" {  true} else {  false }
        let foundPt    = if let v = url.queryItemValue(queries: ["view"]),  v == "pt" {  true} else {  false }
        let foundAtt   = if let v = url.queryItemValue(queries: ["view"]),  v == "att" {  true} else {  false }
        guard foundPrint || foundPt || foundAtt else { return true }
        
        //Create Filer Items

/*
        //Create Item
        let item = Upload_Item(remoteURL: url, type:  foundPt  ? .pdf : .file, temporaryName:webView.title ?? "Untitled File")
        if immediateFiling {
            //will present sheet that downloads the file
            self.uploadItem = item
        } else {
            //adds to the Upload_Items list of files to be downloaded later
            Task { await downloadLater(item)}
        }
        */
        return false
    }
}



#Preview {
    Inbox_View_Old(websiteURL: URL(string: "https://mail.google.com")!)
}

*/
