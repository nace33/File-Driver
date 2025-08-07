//
//  Drive_Preview.swift
//  Nasser Law Firm
//
//  Created by Jimmy Nasser on 4/1/25.
//

import SwiftUI
import BOF_SecretSauce
import GoogleAPIClientForREST_Drive


struct Drive_Preview : View {
//    let url : URL
    let file : GTLRDrive_File
    init(fileID:String) {
//        print("ID: \(fileID)")
//        self.url = URL(string: "https://drive.google.com/file/d/\(fileID)/preview")!
        self.file = GTLRDrive_File()
        file.mimeType = "application/pdf"
        file.identifier = fileID
//        print("URL: \(url)\n\n")
    }
    init(file:GTLRDrive_File) {
        self.file = file
    }

    var body: some View {
        DriveFileView([file])
    }
}
