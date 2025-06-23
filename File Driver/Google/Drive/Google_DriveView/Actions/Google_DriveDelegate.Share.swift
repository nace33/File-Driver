//
//  Google_DriveDelegate.Share.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/23/25.
//


//MARK: - Share
import SwiftUI
import GoogleAPIClientForREST_Drive

extension Google_DriveDelegate {
    func canShare(file:GTLRDrive_File?) -> Bool {
        file != nil || stack.last != nil
    }
    func performActionShare(_ item:GTLRDrive_File?) {
        self.shareItem = item ?? stack.last
    }
    @ViewBuilder func shareView(_ item:GTLRDrive_File) -> some View {
        Google_Drive_Permissions(file: item)
    }
}
