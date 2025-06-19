//
//  Contact.Image.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/10/25.
//

import Foundation


extension Contact : Drive_Cache{
    var cacheID : String {
        label.iconID
    }
    var cacheDirectory: URL? {
        guard let letter = label.name.first else { return nil}
        return URL.applicationSupportDirectory.appending(path: "Contacts" , directoryHint: .isDirectory)
                                              .appending(path: "\(letter)", directoryHint: .isDirectory)
    }
    var cacheURL: URL? {
        guard let cacheDirectory else { return nil }
        return cacheDirectory.appending(path: "\(cacheID).png", directoryHint: .notDirectory)
    }
}
