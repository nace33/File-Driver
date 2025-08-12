//
//  Google.swift
//  File Driver
//
//  Created by Jimmy on 6/19/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct DriveSelector: View {
    let title : String
    let canLoadFolders : Bool
    let showCancelButton : Bool
    @Binding var file   : GTLRDrive_File
    @Binding var fileID : String
    typealias fileSelection = (GTLRDrive_File)-> Bool //returning false will present dismiss from being called
    var selected : fileSelection?
    @State private var driveDelegate : DriveDelegate
    @Environment(\.dismiss) var dismiss
    
    init(_ title: String, showCancelButton:Bool = false, canLoadFolders:Bool, fileID: Binding<String>, mimeTypes:[GTLRDrive_File.MimeType] = [.folder]) {
        self.title = title
        self.showCancelButton = showCancelButton
        _fileID = fileID
        driveDelegate = DriveDelegate.selecter(mimeTypes: mimeTypes)
        self.selected = nil
        self.canLoadFolders = canLoadFolders
        _file = .constant(GTLRDrive_File())
    }
    init(_ title: String, showCancelButton:Bool = false, canLoadFolders:Bool, mimeTypes:[GTLRDrive_File.MimeType] = [.folder], selected:@escaping fileSelection) {
        self.title = title
        self.showCancelButton = showCancelButton
        _fileID = .constant("")
        driveDelegate = DriveDelegate.selecter(mimeTypes: mimeTypes)
        self.selected = selected
        self.canLoadFolders = canLoadFolders
        _file = .constant(GTLRDrive_File())
    }
    init(_ title: String, showCancelButton:Bool = false, canLoadFolders:Bool, file:Binding<GTLRDrive_File>, mimeTypes:[GTLRDrive_File.MimeType] = [.folder]) {
        self.title = title
        self.showCancelButton = showCancelButton
        _fileID = .constant("")
        driveDelegate = DriveDelegate.selecter(mimeTypes: mimeTypes)
        self.selected = nil
        self.canLoadFolders = canLoadFolders
        _file = file
    }
    
    
    var body : some View {
        DriveView(title, delegate: $driveDelegate, canLoad: { _ in canLoadFolders})
            .onAppear() {
                driveDelegate.actions = canLoadFolders ? [.newFolder, .select] : [.select]
            }
            .onChange(of: driveDelegate.selectItem) { _, newValue in
                if let newValue {
                    let shouldDismiss = selected?(newValue) ?? true
                    self.file = newValue
                    self.fileID = newValue.id
                    if shouldDismiss, showCancelButton {
                        dismiss()
                    }
                }
            }
            .toolbar {
                if showCancelButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss()}
                    }
                }
            }
            .presentationSizing(.fitted) // Allows resizing, sizes to content initially
            .frame(idealWidth: 500, minHeight:400, idealHeight:  400 ) 
    }
}
