//
//  Google.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/18/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive


struct DriveView_ActionBar: View {
    @Environment(DriveDelegate.self) var delegate

    var body: some View {
        HStack {
            ForEach(delegate.actions, id:\.self) { action in
                if DriveDelegate.Action.toolbarActions.contains(action) {
                    DriveView_ActionButton(action: action)
                }
            }
        }
    }
}


struct DriveView_ActionButton: View {
    @Environment(DriveDelegate.self) var delegate
    let action : DriveDelegate.Action
    var body: some View {
        switch action {
        case .filter:
            TextField("Filter", text:Bindable(delegate).filter)
                .frame(maxWidth:150)
                .textFieldStyle(.roundedBorder)
        case .select:
            Button(action.title) {
                delegate.perform(action, on: delegate.selection)
            }
                .buttonStyle(.borderedProminent)
                .disabled(!delegate.canPerform(action, on: delegate.selection))
                .layoutPriority(1)
                .fixedSize()
        default:
            Button {
                delegate.perform(action, on: delegate.selection)
            } label: {
                Image(systemName: action.iconName)
            }
                .disabled(!delegate.canPerform(action, on: delegate.selection))
        }
    }
}
