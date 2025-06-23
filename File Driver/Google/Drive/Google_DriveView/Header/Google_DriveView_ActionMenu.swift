//
//  Google_DriveViewActions.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/23/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct Google_DriveView_ActionMenu: View {
    let files : Set<GTLRDrive_File>
    @Environment(Google_DriveDelegate.self) var delegate

    var body: some View {
        let actions = delegate.availableActions(for: files)
        
        if actions.count > 0 {
            ForEach(actions, id:\.self) { action in
                Button(action.title) {
                    delegate.perform(action, on: files)
                }
            }
        }
    }
}

