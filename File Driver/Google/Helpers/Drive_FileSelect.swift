//
//  Drive_FileSelect.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct Drive_FileSelect: View {
    let title : String
    let onlyFolders : Bool
    let mimeTypes : [GTLRDrive_File.MimeType]?
    let selected : (GTLRDrive_File) -> Void
    @State private var selectedFile : GTLRDrive_File?
    
    var body: some View {
        VStack(alignment:.leading, spacing: 0) {
            HStack {
                Text(title).font(.title2)
                Spacer()
                Button("Select") { selected(selectedFile!)}
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedFile == nil)
            }.padding()
            Divider()
            Drive_Navigator(rootID:"", rootname:"Shared Drives", onlyFolders: onlyFolders) { action, file in
                process(file: file, action: action)
            }
        }
        .frame(height: 400)

    }
    
    func process(file:GTLRDrive_File?, action:Drive_Navigator.Action) {
        guard let file else { selectedFile = nil; return }
        
        if let mimeTypes  {
            if mimeTypes.contains(file.mime) {
                selectedFile = file
            }
        } else {
            selectedFile = file
        }
    }
}

#Preview {
    Drive_FileSelect(title:"Select a File", onlyFolders: false, mimeTypes: [.sheet]) {
        print("Selected: \($0.title)")
    }
        .environment(Google.shared)
}
