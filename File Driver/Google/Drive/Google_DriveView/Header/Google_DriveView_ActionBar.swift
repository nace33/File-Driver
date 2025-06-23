//
//  Google.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/18/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive


struct Google_DriveView_ActionBar: View {
    @Environment(Google_DriveDelegate.self) var delegate

    var body: some View {
        HStack {
            let files = delegate.selection
            ForEach(delegate.actions, id:\.self) { action in
                if Google_DriveDelegate.Action.toolbarActions.contains(action) {
                    switch action {
                    case .filter:
                        TextField("Filter", text:Bindable(delegate).filter)
                            .frame(maxWidth:150)
                            .textFieldStyle(.roundedBorder)
                    case .select:
                        Button(action.title) {
                            delegate.perform(action, on: files)
                        }
                            .buttonStyle(.borderedProminent)
                            .disabled(!delegate.canPerform(action, on: files))
                    default:
                        Button {
                            delegate.perform(action, on: files)
                        } label: {
                            Image(systemName: action.iconName)
                        }
                            .disabled(!delegate.canPerform(action, on: files))
                    }
                }
            }
        }
    }
}


