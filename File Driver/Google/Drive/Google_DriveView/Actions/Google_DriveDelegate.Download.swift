//
//  DownloadItem.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/23/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

//MARK: - Download
extension Google_DriveDelegate {
    func canDownload(file:GTLRDrive_File?) -> Bool {
        guard let file               else { return false }
        guard !file.isFolder         else { return false }
        guard !file.isShortcutFolder else { return false }
        guard let dID = file.driveId else { return false }
        guard file.id != dID         else { return false }
        return file != stack.last
    }
    func performActionDownload(_ file:GTLRDrive_File?) {
        guard let file = file else { return }
        Task {
            await download(file)
        }
    }
    func download(_ file:GTLRDrive_File) async {
        do {
            downloadItems.append(.init(file: file))
            let download = try await Google_Drive.shared.download(file) { progress in
                if let index = self.downloadItems.firstIndex(where: {$0.id == file.id }) {
                    self.downloadItems[index].progress = progress
                }
            }
            downloadData = download
            downloadFilename = file.downloadFilename
            showDownloadExport = true
            _ = downloadItems.remove(id:file.id)
        } catch {
            _ = downloadItems.remove(id:file.id)
            downloadData = Data()
            downloadFilename = nil
            self.error = error
        }
    }
    func processExportResult(_ result:Result<URL, Error>) {
        switch result {
        case .success(let urls):
            print("Exported: \(urls)")
            break
        case .failure( let error):
            print("Export Failed: \(error.localizedDescription)")
            self.error = error
        }
        downloadData = Data()
        downloadFilename = nil
    }
    struct DownloadItem : Identifiable {
        var id       : String { file.id }
        let file     : GTLRDrive_File
        var error    : Error?
        var progress : Float = 0
    }
}
