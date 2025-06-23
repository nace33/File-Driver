//
//  UploadItem.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/23/25.
//
import SwiftUI
import GoogleAPIClientForREST_Drive
import UniformTypeIdentifiers

//MARK: - Upload
extension Google_DriveDelegate {
    func canUpload(to item:GTLRDrive_File?) -> Bool {
        (item?.isFolder ?? false) || (stack.last != nil)
    }

    func performActionUpload() {
        showUploadSheet = true
    }
    func upload(_ urls:[URL], to folder:GTLRDrive_File?) {
        guard let folder = folder ?? stack.last else { return }
        let parentID = folder.id
        guard  !parentID.isEmpty else { return }
        
        
        for url in urls {
            Task {
                _ = url.startAccessingSecurityScopedResource()
                
                let uploadItem : UploadItem
                
                if folder == stack.last {
                    //uploading into the main displayed folder
                    uploadItem = UploadItem(id:url.absoluteString, title:url.lastPathComponent)
                    let temporaryFile = GTLRDrive_File()
                    temporaryFile.identifier = url.absoluteString
                    temporaryFile.name = url.lastPathComponent
                    temporaryFile.mimeType = url.fileType
                    self.files.append(temporaryFile)
                    sortFiles()
                } else { //uploading to a folder in the main display
                    uploadItem =   UploadItem(id:folder.id, title:folder.title)
                }
            
                
                uploadItems.append(uploadItem)
                let uploadedFile : GTLRDrive_File
                 uploadedFile =  try await Google_Drive.shared.upload(url:url, to: parentID) { progress in
                    if let index = self.uploadItems.firstIndex(where: {$0.id == uploadItem.id}) {
                        self.uploadItems[index].progress = progress
                    }
                }
                
                if let index = files.firstIndex(where: {$0.id == url.absoluteString}) {
                    self.files.remove(at: index)
                    self.files.insert(uploadedFile, at: index)
                }
                
                _ = uploadItems.remove(id: uploadItem.id)
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
    internal struct UploadItem : Identifiable {
        var id       : String
        var title    : String
        var progress : Double = 0
    }
    static var urlTypes : [UTType] {[
        .folder, .audio, .video, .image, .pdf, .text, .movie, .emailMessage, .message, .spreadsheet, .presentation, .package, .script, .fileURL, UTType(filenameExtension: "pages")!
    ]}
}
