//
//  Google.swift
//  File Driver
//
//  Created by Jimmy on 6/19/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct Google_DriveSelector: View {
    let title : String
    let canLoadFolders : Bool
    @Binding var file   : GTLRDrive_File
    @Binding var fileID : String
    typealias fileSelection = (GTLRDrive_File)-> Void
    var selected : fileSelection?
    @State private var driveDelegate : Google_DriveDelegate

    init(_ title: String, canLoadFolders:Bool, fileID: Binding<String>, mimeTypes:[GTLRDrive_File.MimeType] = [.folder]) {
        self.title = title
        _fileID = fileID
        driveDelegate = Google_DriveDelegate.selecter(mimeTypes: mimeTypes)
        self.selected = nil
        self.canLoadFolders = canLoadFolders
        _file = .constant(GTLRDrive_File())
    }
    init(_ title: String, canLoadFolders:Bool, mimeTypes:[GTLRDrive_File.MimeType] = [.folder], selected:@escaping fileSelection) {
        self.title = title
        _fileID = .constant("")
        driveDelegate = Google_DriveDelegate.selecter(mimeTypes: mimeTypes)
        self.selected = selected
        self.canLoadFolders = canLoadFolders
        _file = .constant(GTLRDrive_File())
    }
    init(_ title: String, canLoadFolders:Bool, file:Binding<GTLRDrive_File>, mimeTypes:[GTLRDrive_File.MimeType] = [.folder]) {
        self.title = title
        _fileID = .constant("")
        driveDelegate = Google_DriveDelegate.selecter(mimeTypes: mimeTypes)
        self.selected = nil
        self.canLoadFolders = canLoadFolders
        _file = file
    }
    
    
    var body : some View {
        Google_DriveView(title, delegate: $driveDelegate, canLoad: { _ in canLoadFolders})
            .onChange(of: driveDelegate.selectItem) { _, newValue in
                if let newValue, newValue.id == newValue.driveId {
                    selected?(newValue)
                    self.file = newValue
                    self.fileID = newValue.id
                }
            }
    }
}
