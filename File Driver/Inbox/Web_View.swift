//
//  WebView2.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/2/25.
//
/*
import SwiftUI
import WebKit

#if os(macOS)
public struct Web_View: NSViewRepresentable {
    ///do not use completion handle style call backs to BOF_WebView, itself, as SwiftUI then updates the view from those
    ///Instead use deledgate completion handlers since those can occur outside of a (var body : View) and avoid re-draw/loading
    let url         : URL
    let userAgent   : String
    let delegate : Web_View.Delegate
    
    public static var defaultUserAgent : String { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15" }
    
    public init(_ url: URL, userAgent:String? = nil, delegate : Web_View.Delegate = .init()) {
        self.url = url
        self.userAgent = userAgent ?? Web_View.defaultUserAgent
        self.delegate = delegate
    }
    
    public func makeNSView(context: Context) -> some NSView {
        let webView = WKWebView()
 
        
        webView.customUserAgent    = userAgent
        webView.navigationDelegate = delegate
        webView.uiDelegate         = delegate
        webView.load(URLRequest(url: url))
        return webView
    }
    
    public func updateNSView(_ view: NSViewType, context: Context) {
        if let webView = view as? WKWebView,
           webView.url != url {
            webView.navigationDelegate = delegate
            webView.uiDelegate = delegate
            webView.load(URLRequest(url: url))
        }
    }
}
#else
public struct Web_View: UIViewRepresentable {
    ///do not use completion handle style call backs to BOF_WebView, itself, as SwiftUI then updates the view from those
    ///Instead use deledgate completion handlers since those can occur outside of a (var body : View) and avoid re-draw/loading
    let url         : URL
    let userAgent   : String
    let delegate : Web_View.Delegate
    
    public static var defaultUserAgent : String { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15" }
    
    public init(_ url: URL, userAgent:String? = nil, delegate : Web_View.Delegate = .init()) {
        self.url = url
        self.userAgent = userAgent ?? Web_View.defaultUserAgent
        self.delegate = delegate
    }
    
    public func makeUIView(context: Context) -> some NSView {
        let webView = WKWebView()
 
        
        webView.customUserAgent    = userAgent
        webView.navigationDelegate = delegate
        webView.uiDelegate         = delegate
        webView.load(URLRequest(url: url))
        return webView
    }
    
    public func updateUIView(_ view: UIViewType, context: Context) {
        if let webView = view as? WKWebView,
           webView.url != url {
            webView.navigationDelegate = delegate
            webView.uiDelegate = delegate
            webView.load(URLRequest(url: url))
        }
    }
}
#endif


public extension Web_View {
    @Observable
    class Delegate : NSObject, WKNavigationDelegate, WKDownloadDelegate, WKUIDelegate {
        //set in init
        private let downloadDirectory : URL
        let clicked : ((URL, WKWebView) -> Bool)?
        private let loading           : ((LoadStatus, WKWebView) -> Void)?
        private let downloadPolicy    : ((WKNavigationResponse) -> WKNavigationResponsePolicy)?
        private let downloadDelegate  : ((WKDownload) -> (any WKDownloadDelegate)?)?
        private let downloading       : ((LoadStatus, WKDownload) -> Void)?
        
        public init(downloadDirectory: URL? = nil,
                    clicked: ((URL, WKWebView) -> Bool)? = nil,
                    loading: ((LoadStatus, WKWebView) -> Void)? = nil,
                    downloadPolicy: ((WKNavigationResponse) -> WKNavigationResponsePolicy)? = nil,
                    downloadDelegate: ((WKDownload) -> (any WKDownloadDelegate)?)? = nil,
                    downloading: ((LoadStatus, WKDownload) -> Void)? = nil) {
            self.downloadDirectory = downloadDirectory ?? URL.downloadsDirectory
            self.clicked = clicked
            self.loading = loading
            self.downloadPolicy = downloadPolicy
            self.downloadDelegate = downloadDelegate
            self.downloading = downloading
        }
        
        #if os(macOS)
        private var printCompleted : ((Bool) -> ())?
        #endif
        
        //Set in methods below
        private var urlLoadObserver   : NSKeyValueObservation?
        private var downloadObserver  : NSKeyValueObservation?
        
        //Enum
        public enum LoadStatus  : Equatable    {
            case loading(Double), finished, error(Error)
            public static func == (lhs: Web_View.Delegate.LoadStatus, rhs: Web_View.Delegate.LoadStatus) -> Bool {
                lhs.intValue == rhs.intValue
            }
            var intValue : Int {
                switch self {
                case .loading  : 0
                case .finished : 1
                case .error    : 2
                }
            }
        }
        
        //MARK: - Navigation Loading
        public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            ///Do not send loadStatus in didStartProvisionalNavigation because the navigation can transition to a download and didFinish, didFail will not be called.
            ///send loadStatus now that webView has committed to loading the URL
            self.loading?(.loading(webView.estimatedProgress), webView)
           
            self.urlLoadObserver = webView.observe(\.estimatedProgress) { webView, _ in
                self.loading?(.loading(webView.estimatedProgress), webView) //
            }
        }
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.loading?(.finished, webView)
        }
        public func webView(_ webView: WKWebView, didFail   navigation: WKNavigation!, withError error: any Error) {
            self.loading?(.error(error), webView)
        }
        
        
        //MARK: - Download Policy
        //https://dev.to/gualtierofr/download-files-in-a-wkwebview-boo
        ///allow, cancel or initiate download
        ///"application/force-download"
        public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
            guard let downloadPolicy else {
                //default
                let defaultMimeTypes = ["application/pdf", "application/force-download", "application", "image", "audio", "video"]
                if let mimeType = navigationResponse.response.mimeType,
                   defaultMimeTypes.filter({ mimeType == $0 || mimeType.hasPrefix($0)}).count > 0 {
                    return .download
                }
                else if !navigationResponse.canShowMIMEType {
                    return .download
                }
                else {
                    return .allow
                }
            }
            return downloadPolicy(navigationResponse)
        }

        
        //MARK: - Download Delegate
        ///allow, cancel or initiate download
        public func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
            guard let downloadDelegate, let del = downloadDelegate(download) else {
                download.delegate = self
                self.downloading?(.loading(download.progress.fractionCompleted), download)
                
                self.downloadObserver = download.observe(\.progress.fractionCompleted) { download, _ in
                    self.downloading?(.loading(download.progress.fractionCompleted), download)
                }
                return
            }
            download.delegate = del
        }
        public func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String) async -> URL? {
            let directory = downloadDirectory
            let temp = directory.appendingPathComponent(suggestedFilename)
            let ext  = temp.pathExtension
            let name = temp.deletingPathExtension().lastPathComponent
            let uniqueURL = FileManager.uniqueURL(for: name, ext: ext, at:directory)
            //if url is not unique, then download will fail
            return uniqueURL
        }
        public func downloadDidFinish(_ download: WKDownload) {
            self.downloading?(.finished, download)
        }
        public func download(_ download: WKDownload, didFailWithError error: any Error, resumeData: Data?) {
            self.downloading?(.error(error), download)
        }
        
        
        //MARK: Clicked
        ///Called when webview/user wants to open a new window
        ///Default behavior is to check delegate to see if can open in same window, otherwise, does not open
        public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url,
               let clicked,
               clicked(url, webView) {
                ///the delegate call back has allowed the url to be loaded in the browser
                webView.load(URLRequest(url: url))
            }
            else if clicked == nil,
                    let url = navigationAction.request.url {
                ///navigationDelegate exists, but allows all urls to be loaded
                webView.load(URLRequest(url: url))
            }
            ///returning nil means not creating a new webView
            return nil
        }

        
        //MARK: Upload
        ///Call open panel and return selected urls to initate file upload
        ///Unsure how to get notification of upload status/completed
        public func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo) async -> [URL]? {
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles       = true
            openPanel.canChooseDirectories = parameters.allowsDirectories
            openPanel.allowsMultipleSelection = parameters.allowsMultipleSelection
            if openPanel.runModal() == .OK {
                return openPanel.urls
            } else {
                return nil
            }
        }
        
        
        //MARK: Print
        #if os(macOS)
        public func print(webView:WKWebView, saveURL:URL, paperSize:CGSize = .init(width: 612, height: 792), margin:CGFloat = 18.0) async -> Bool {
            return await withCheckedContinuation { cont in
                guard let window = NSApplication.shared.windows.first else {
                    cont.resume(returning: false)
                    return
                }
                self.printCompleted = { success in
                    cont.resume(returning: success)
                }
                let printOpts: [NSPrintInfo.AttributeKey : Any] = [
                    NSPrintInfo.AttributeKey.jobDisposition : NSPrintInfo.JobDisposition.save,
                    NSPrintInfo.AttributeKey.jobSavingURL   :saveURL,
                    NSPrintInfo.AttributeKey.paperSize      :paperSize,
                    NSPrintInfo.AttributeKey.topMargin      :margin,
                    NSPrintInfo.AttributeKey.bottomMargin   :margin,
                    NSPrintInfo.AttributeKey.leftMargin     :margin,
                    NSPrintInfo.AttributeKey.rightMargin    :margin
                ]
                let pi = NSPrintInfo(dictionary: printOpts)
                
                let po = webView.printOperation(with: pi)
                
                po.view?.frame = CGRect(x: 0,y: 0, width: pi.paperSize.width, height: pi.paperSize.height);
                
                po.showsPrintPanel = false
                po.showsProgressPanel = false
                
                let selector = #selector(self.printOperationDidRun(printOperation: success: contextInfo:))
                DispatchQueue.main.async {
                    po.runModal(for:window, delegate: self, didRun: selector, contextInfo: nil)
                }
            }
        }
        @objc nonisolated func printOperationDidRun(printOperation:NSPrintOperation, success:Bool, contextInfo:UnsafeMutableRawPointer?) {
            DispatchQueue.main.async {
                if let completed = self.printCompleted {
                    completed(success)
                }
            }
        }
        #else
        public func print(webView:WKWebView, saveURL:URL, paperSize:CGSize = .init(width: 612, height: 792), margin:CGFloat = 18.0) async -> Bool {
            webView.bounds = CGRect(origin: CGPoint.zero, size: paperSize)
            
            //create print formatter object
            let printFormatter = webView.viewPrintFormatter()
            
            // create renderer which renders the print formatter's content on pages
            let renderer = UIPrintPageRenderer()
            renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
            
            // Set page sizes and margins to the renderer
            let paperRect = CGRect(x: 0, y: 0, width: paperSize.width, height: paperSize.height)
            renderer.setValue(NSValue(cgRect:paperRect), forKey: "paperRect")
            
            let printableRect = CGRect(x: margin, y:margin, width: paperSize.width - (2 * margin), height: paperSize.height - (2 * margin))
            renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
            
            // Start a pdf graphics context. This makes it the current drawing context and every drawing command after is captured and turned to pdf data
            guard UIGraphicsBeginPDFContextToFile(saveURL.path, paperRect, nil) else {  return false   }
            //        UIGraphicsBeginPDFContextToFile
            // Loop through number of pages the renderer says it has and on each iteration it starts a new pdf page
            for i in 0..<renderer.numberOfPages {
                UIGraphicsBeginPDFPage()
                // draw content of the page
                renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
            }
            // Close pdf graphics context
            UIGraphicsEndPDFContext()
            return true
        }
        #endif
    }
}

public extension Web_View {
    
    @Observable
    
    class DownloadDelegate : NSObject, WKDownloadDelegate {
        var status : Web_View.Delegate.LoadStatus = .loading(0)
        
        //MARK: - Download Delegate
        public func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String) async -> URL? {
            let directory = URL.downloadsDirectory
            let temp = directory.appendingPathComponent(suggestedFilename)
            let ext  = temp.pathExtension
            let name = temp.deletingPathExtension().lastPathComponent
            let uniqueURL = FileManager.uniqueURL(for: name, ext: ext, at:directory)
            //if url is not unique, then download will fail
            
            return uniqueURL
        }
        public func downloadDidFinish(_ download: WKDownload) {
            self.status = .finished
        }
        public func download(_ download: WKDownload, didFailWithError error: any Error, resumeData: Data?) {
            self.status = .error(error)
            
        }
    }
}
*/
