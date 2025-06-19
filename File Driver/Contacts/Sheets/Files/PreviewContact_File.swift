//
//  PreviewContact_File.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/12/25.
//

import SwiftUI

struct PreviewContact_File: View {
    let file : Contact.File
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(alignment:.leading) {
            Google_Drive_Preview(fileID: file.fileID)
        }
        .frame(width:600, height:600)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss()}
            }
        }
    }
}

