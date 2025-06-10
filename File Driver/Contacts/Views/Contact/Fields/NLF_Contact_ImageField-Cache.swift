//
//  NLF_Contact_ImageField-Cache.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/5/25.
//

import Foundation

//MARK: Cache
extension NLF_Contact_ImageField {
    var cacheDirectory: URL? {
        guard let letter = contact.name.first else { return nil}
        return URL.applicationSupportDirectory.appending(path: "Contacts" , directoryHint: .isDirectory)
                                              .appending(path: "\(letter)", directoryHint: .isDirectory)
    }
    var cacheURL: URL? {
        guard let cacheDirectory else { return nil }
        return cacheDirectory.appending(path: "\(contact.id).png", directoryHint: .notDirectory)
    }
    func cacheImage(_ data:Data) throws {
        guard let cacheDirectory else { return }
        guard let cacheURL else { return }
        do {
            try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            try data.write(to: cacheURL)
        } catch {
            throw error
        }
    }
    func getCacheImage() throws -> Data  {
        guard let cacheURL else { throw  NSError.quick("No Cache URL") }
        do {
            return try Data(contentsOf: cacheURL)
        } catch {
            throw error
        }
    }
    func clearCache() {
        if let cacheURL {
            try? FileManager.default.trashItem(at: cacheURL, resultingItemURL: nil)
        }
    }
}
