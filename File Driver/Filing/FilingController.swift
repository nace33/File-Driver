//
//  FilingController.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

@Observable
final class FilingController {
    static let shared: FilingController = { FilingController() }()
    var items  : [FilingItem] = []

}

//MARK: - Computed Properties
extension FilingController {
    var driveID : String? { UserDefaults.standard.string(forKey: BOF_Settings.Key.filingDrive.rawValue)}
    
    var currentUploads : [FilingItem] { items.filter { $0.isUploading}}

    func index(of itemID:FilingItem.ID) -> Int? {
        items.firstIndex(where: {$0.id == itemID})
    }
}

//MARK: - Load
extension FilingController {
    func load() async throws(Filing_Error) {
        do throws(Filing_Error) {
            guard let driveID else { throw .filingDriveNotSet }
            do {
                items = try await Google_Drive.shared.getContents(driveID: driveID)
                                                           .compactMap { .init(file: $0)}
                sortItems()
            } catch {
                throw Filing_Error.uploadFailed(error.localizedDescription)
            }
        } catch {
            throw error
        }
    }
    func sortItems() {
        items.sort { lhs, rhs in
            lhs.dateAdded > rhs.dateAdded
        }
    }
}

//MARK: - Filing Items
extension FilingController {
    func createFilingItem(for url: URL) async throws(Filing_Error) -> FilingItem {
        do throws(Filing_Error){
            guard let driveID                            else { throw .filingDriveNotSet}
            guard let newItem = FilingItem(fileURL: url) else { throw .invalidURL}
            items.append(newItem)
            sortItems()
            guard let index = items.firstIndex(where: {$0.id == newItem.id}) else { throw .transitItemNotFound }
            let boundItem = Bindable(self).items[index]
            
            do {
//                boundItem.wrappedValue.status = .uploading //this is set in the init FilingItem(fileURL: url)
                let uploadedFile =  try await Google_Drive.shared.upload(url:url, to: driveID) { progress in
                    if progress == 1 {
                        withAnimation {
                            boundItem.wrappedValue.progress =  1
                        }
                    } else {
                        boundItem.wrappedValue.progress =  progress
                    }
                }
                boundItem.wrappedValue.file = uploadedFile
                boundItem.wrappedValue.status = .readyToFile
            } catch {
                boundItem.wrappedValue.status = .failed
                let err = Filing_Error.uploadFailed(error.localizedDescription)
                boundItem.wrappedValue.error  = err
                throw err
            }
            return boundItem.wrappedValue
        } catch {
            throw error
        }
    }
}
