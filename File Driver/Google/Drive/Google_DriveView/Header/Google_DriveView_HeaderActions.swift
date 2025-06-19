//
//  Google.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/18/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct Google_DriveView_HeaderActions: View {
    let file : GTLRDrive_File?
    let style : Google_DriveView_ActionButton.Style
    @Environment(Google_DriveDelegate.self) var delegate
    var body: some View {
        HStack {
            Google_DriveView_HeaderActionButtons(file: file, style: style)
        }
    }
}

struct Google_DriveView_HeaderActionButtons: View {
    let file : GTLRDrive_File?
    let style : Google_DriveView_ActionButton.Style
    @Environment(Google_DriveDelegate.self) var delegate
    var body: some View {
        ForEach(delegate.actions, id:\.self) { action in
            if Google_DriveDelegate.Action.toolbarActions.contains(action) {
                Google_DriveView_ActionButton(action: action, style:style, file: file)
            }
        }
    }
}
