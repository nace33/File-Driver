//
//  Google.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//


import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce


struct DriveView_Row : View {
    @Environment(DriveDelegate.self) var delegate
    let file : Binding<GTLRDrive_File>
    init(_ file: Binding<GTLRDrive_File>) {
        self.file = file
    }
    @State private var isTargeted : Bool = false
    
    var body: some View {
        DriveView_RowLabel(file)
            .if((delegate.actions.contains(.move) || delegate.actions.contains(.upload)) && file.wrappedValue.isFolder) { content in
                content
                    .dropStyle(isTargeted:$isTargeted)
                    .dropDestination(for: DropItem.self, action: { items, _ in
                       processItems(items)
                    }, isTargeted: {self.isTargeted = $0})
            }
            .if(delegate.actions.contains(.move) && delegate.canDrag(file: file.wrappedValue)) { content in
                content
                    .draggable(file.wrappedValue.id)
            }
    }
    
    fileprivate func processItems(_ items: [DropItem]) -> Bool {
        processFileMoveItems(items)
        processFileUploadItems(items)
        return true
    }
    fileprivate func processFileMoveItems(_ items: [DropItem])  {
        guard delegate.actions.contains(.move) else { return }
        let fileIDs = items.compactMap { dropItem in
            switch dropItem {
            case .file(let id):
                if delegate.canMove(id: id, newParentID: file.id) {
                    return id
                }
                return nil
            default:
                return nil
            }
        }
        if fileIDs.isNotEmpty {
            Task {
                try? await delegate.move(ids: fileIDs, newParentID: file.id)
            }
        }
    }
    fileprivate func processFileUploadItems(_ items: [DropItem])  {
        guard delegate.actions.contains(.upload) else { return }
        guard delegate.canUpload(to: file.wrappedValue) else { return }
        let urls = items.compactMap { dropItem in
            switch dropItem {
            case .url(let url):
                return url
            default:
                return nil
            }
        }
        if urls.isNotEmpty {
            delegate.upload(urls, to: file.wrappedValue)
        }
    }
}


//MARK: Transferrable
///This is because only one onDropDestination can be applied to a single view
fileprivate
enum DropItem: Codable, Transferable {
    case file(GTLRDrive_File.ID)
    case url(URL)
    
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { DropItem.file($0) }
        ProxyRepresentation { DropItem.url ($0) }
    }
    
    var file: GTLRDrive_File.ID? {
        switch self {
            case .file(let str): return str
            default: return nil
        }
    }
    
    var url: URL? {
        switch self {
            case.url(let url): return url
            default: return nil
        }
    }
}


