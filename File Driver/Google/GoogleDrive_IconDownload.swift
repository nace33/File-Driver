//
//  IconTest.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/27/25.
//

import Foundation
import SwiftUI
import GoogleAPIClientForREST_Drive

struct GoogleDrive_IconDownload : View {
    var size : ImageSize?
    var mimeTypes = GTLRDrive_File.MimeType.allCases
    enum ImageSize : Int, CaseIterable {
        case sixteen = 16
        case thirtyTwo = 32
        case sixtyFour = 64
        case oneTwentyEight = 128
        case twoFiveSix = 256
    }
    @State private var isLoading: Bool = false
    @State private var urls: [URL] = []
    @State private var error : Error?
    @State private var counter = 0
    var body: some View {
        VStack {
             if let error {
                Text("Error \(error.localizedDescription)")
                    .padding()
            } else {
                if isLoading {
                    ProgressView("Downloading Icon \(counter) of \(max)", value: Float(counter) / Float(max))
                        .padding()
                }
                List(urls, id:\.self) { url in
                    Label {
                        Text(url.lastPathComponent)
                    } icon: {
                        if let image = image(url: url) {
                            #if os(macOS)
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                            #else
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                            #endif
                        } else {
                            Image(systemName: "triangle.fill").foregroundStyle(.red)
                        }
                    }
                }
            }
        }
            .task { await download() }
    }
    var max : Int { ImageSize.allCases.count * mimeTypes.count}
    #if os(macOS)
    func image(url:URL) -> NSImage? {
        do {
            let data = try Data(contentsOf: url)
            if let image = NSImage(data: data) {
                return image
            } else { return nil }
        } catch {
            return nil
        }
    }
    #else
    func image(url:URL) -> UIImage? {
        do {
            let data = try Data(contentsOf: url)
            if let image = UIImage(data: data) {
                return image
            } else { return nil }
        } catch {
            return nil
        }
    }
    #endif
    func url(mimeType:GTLRDrive_File.MimeType, size:Int)->URL?{
        let str = "https://drive-thirdparty.googleusercontent.com/\(size)/type/\(mimeType.rawValue)"
        return URL(string: str)!
    }
    
    @MainActor
    func download() async {
        do {
            counter = 0
            isLoading = true
            let directory = URL.downloadsDirectory.appending(path: "Google Drive Icons")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            
            let sizes : [ImageSize]
            if let size { sizes = [size]}
            else { sizes = ImageSize.allCases }
            
            for imageSize in sizes {
                for mimeType in mimeTypes {
                    guard let url = url(mimeType:mimeType, size: imageSize.rawValue) else { return }
                    let tuple = try await URLSession.shared.download(for: URLRequest(url: url))
                    let localURL = tuple.0
                    let filename : String
                    if sizes.count == 1 {
                        filename = mimeType.title + ".png"
                    } else {
                         filename = mimeType.title + "_\(imageSize.rawValue)" + ".png"
                    }
                    let uniqueURL = FileManager.uniqueURL(for: filename, at: directory)
                    try FileManager.default.moveItem(at: localURL, to: uniqueURL)
                    DispatchQueue.main.async {
                        urls.append(uniqueURL)
                        counter += 1
                        print("Downloading Icon: \(counter) of \(max) = \(Float(counter) / Float(max) * 100)%")
                    }
                }
            }

            isLoading = false
        } catch {
            isLoading = false
        }

    }
}
