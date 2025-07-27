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
extension DriveDelegate {
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
                let gmailThread = url.emailThread
                print(gmailThread)
                let appProperties = gmailThread.driveAppProperties
                print("\n\nAppProperties: \(appProperties)")
//                let descriptionString = gmailThread.gtlrDescription(style:.full)
//                print("descriptionString: \(descriptionString)")
                
                
                
                let filename : String
                if let autoFilename = await AutoFile_Rename.proposedFilename(for: url, thread:gmailThread) {
                    filename = autoFilename
                } else {
                    filename = url.lastPathComponent
                }
       
                
                let uploadItem : UploadItem
                
                if folder == stack.last {
                    //uploading into the main displayed folder
                    uploadItem = UploadItem(id:url.absoluteString, title:filename)
                    let temporaryFile = GTLRDrive_File()
                    temporaryFile.identifier = url.absoluteString
                    temporaryFile.name = filename
                    temporaryFile.mimeType = url.fileType
                    temporaryFile.createdTime   = GTLRDateTime(date:url.dateCreated ?? Date.now)
                    temporaryFile.modifiedTime = GTLRDateTime(date: url.dateModified ?? Date.now)
                    temporaryFile.appProperties = appProperties
                    self.files.append(temporaryFile)
                    sortFiles()
                } else { //uploading to a folder in the main display
                    uploadItem =   UploadItem(id:folder.id, title:folder.title)
                }
            
                
                uploadItems.append(uploadItem)
                do {
                    let uploadedFile : GTLRDrive_File =  try await Drive.shared.upload(url:url, filename: filename, to: parentID, description: nil, appProperties:appProperties) { progress in
                        if let index = self.uploadItems.firstIndex(where: {$0.id == uploadItem.id}) {
                            self.uploadItems[index].progress = progress
                        }
                    }
                    
                    uploadedFile.appProperties = appProperties
                    if let index = files.firstIndex(where: {$0.id == url.absoluteString}) {
                        self.files.remove(at: index)
                        self.files.insert(uploadedFile, at: index)
                    }
                    
                    _ = uploadItems.remove(id: uploadItem.id)
                    url.stopAccessingSecurityScopedResource()
                } catch {
                    _ = uploadItems.remove(id: uploadItem.id)
                    _ = self.files.remove(id: url.absoluteString)
                    url.stopAccessingSecurityScopedResource()
                }
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



//Headers
/*
 public let headerString: String
 public let date        : Date
 public let contacts    : [PDFGmail_Contact]
 //    public let selection   : PDFSelection
 public var overallYPos : Float
 */

//Contact
/*
 public let email: String
 public let name: String
 public let emailHost : String
 public let category : Category
 public enum Category : String, CaseIterable, Codable, Hashable {
     case from, to, cc, bcc
 }
*/
