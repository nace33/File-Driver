//
//  Drive.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/10/25.
//

import Foundation

protocol Drive_Cache : Equatable {
    //the drive ID of the file
    var cacheID : String { get  }
    //Local Directory and URL to save data to
    var cacheDirectory : URL? { get  }
    var cacheURL: URL? { get  }
}



@Observable
final class Drive_DataCache<T:Drive_Cache> {
    var item :T? {
        didSet {
            Task { await downloadData() }
        }
    }
    private(set) var isLoading = false
    private(set) var error : Error?
    var data : Data?
    
    
    //Call
    func clearCache() throws {
        do {
            if let cacheURL  = item?.cacheURL {
                try FileManager.default.trashItem(at: cacheURL, resultingItemURL: nil)
                data = nil
            }
        } catch {
            throw error
        }
    }
    func refresh() {
        data = nil
        try? data = getCacheData()
    }
    
    //Cache
    private func cacheData(_ data:Data) throws {
        guard let cacheDirectory = item?.cacheDirectory else { return }
        guard let cacheURL = item?.cacheURL else { return }
        do {
            try FileManager.default.createDirectory(at:cacheDirectory, withIntermediateDirectories: true)
            try data.write(to: cacheURL)
        } catch {
            throw error
        }
    }
    private func getCacheData() throws -> Data  {
        guard let cacheURL  = item?.cacheURL else { throw  NSError.quick("No Cache URL") }
        do {
            return try Data(contentsOf: cacheURL)
        } catch {
            throw error
        }
    }
 
    
    //download
    private func downloadData() async {
        do {
            do {
                data = try getCacheData()
            } catch {
                guard  let id = item?.cacheID, id.count > 0 else {
                    throw NSError.quick("No Cache ID")
                }
                
                isLoading = true
                let iconFile = try await Google_Drive.shared.download(id:id)
                try cacheData(iconFile.data)
                data = iconFile.data
                isLoading = false
            }
        } catch {
            isLoading = false
            data = nil
            self.error = error
        }
    }
}
