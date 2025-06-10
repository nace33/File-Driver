//
//  Google_Drive_Preview.swift
//  Nasser Law Firm
//
//  Created by Jimmy Nasser on 4/1/25.
//

import SwiftUI
import BOF_SecretSauce
import GoogleAPIClientForREST_Drive


struct Google_Drive_Preview : View {
    var url : URL
    @State private var didLoadPreview:Bool = false
    init(fileID:String) {
//        print("ID: \(fileID)")
        self.url = URL(string: "https://drive.google.com/file/d/\(fileID)/preview")!
//        print("URL: \(url)\n\n")
    }
    init(file:GTLRDrive_File) {
//        if let webViewLink = file.webViewLink {
//            self.url = URL(string:webViewLink)!
//        } else {
            self.url = file.previewURL
//        }
    
    }

    var body: some View {
        ZStack {
            if !didLoadPreview { ProgressView("Loading Preview...") }
            BOF_WebView(url, navDelegate: BOF_WebView.NavDelegate(loadStatus: { status, _ in
                switch status {
                case .finished: didLoadPreview = true
                default: break
                }
            }), uiDelegate:.init())
         
                .task(id:url.absoluteString) { didLoadPreview = false}
                .opacity(didLoadPreview ? 1 : 0)
        }

    }
}
