//
//  Google.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/17/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

struct Google_DriveView_ActionButton : View {
    @Environment(Google_DriveDelegate.self) var delegate
    let action : Google_DriveDelegate.Action
    let style : Style
    let file: GTLRDrive_File?
    enum Style { case text, image, textAndImage }
    
    var actionFile : GTLRDrive_File? {
        switch action {
        case .select:
            file ?? delegate.selected ?? delegate.stack.last
        default:
            file ?? delegate.selected
        }
    }
    
    var body: some View {
        switch action {
        case .refresh:
            actionButton {
                delegate.refresh()
            }
                .buttonStyle(.link)
        case .select:
            actionButton {
                delegate.selectItem = actionFile
            }
        case .rename:
            actionButton {
                delegate.renameItem = actionFile
            }
        case .newFolder:
            actionButton {
                delegate.showNewFolderSheet = true
            }
        case .share:
            actionButton {
                delegate.shareItem = actionFile
            }
        case .upload:
            actionButton {
                delegate.uploadToFolder = actionFile
                delegate.showUploadSheet = true
            }
        case .download:
            actionButton {
                if let actionFile {
                    Task { await delegate.download(actionFile) }
                }
            }
        case .delete:
            actionButton {
                delegate.deleteItem = actionFile
            }
        case .move:
            actionButton { print("This is not intended to have a button") }
        case .filter:
            TextField("Filter", text:Bindable(delegate).filter)
                .frame(maxWidth:150)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    @ViewBuilder func actionButton(performAction:@escaping() -> Void) -> some View {
        switch style {
        case .text:
            Button(action.title) {
                performAction()
            }
            .disabled(!delegate.canPerform(action, on: actionFile))

        case .image:
            if action == .select { //do not allow to present as Image Only
                Button(action.title) {
                    performAction()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!delegate.canPerform(action, on: actionFile))
            } else {
                Button {
                    performAction()
                } label: {
                    Image(systemName:action.iconName)
                }
                    .disabled(!delegate.canPerform(action, on: actionFile))
            }
        case .textAndImage:
            Button(action.title, systemImage: action.iconName) {
                performAction()
            }
                .disabled(!delegate.canPerform(action, on: actionFile))
        }
    }
}
