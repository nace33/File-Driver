//
//  Google.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//


import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce


struct Google_DriveView_Row : View {
    @Environment(Google_DriveDelegate.self) var delegate
    let file : Binding<GTLRDrive_File>
    init(_ file: Binding<GTLRDrive_File>) {
        self.file = file
    }
    @State private var isTargeted : Bool = false
    
    var body: some View {
        Google_DriveView_RowLabel(file)
            .if((delegate.actions.contains(.move) || delegate.actions.contains(.upload)) && file.wrappedValue.isFolder) { content in
                content
                    .dropStyle(isTargeted:$isTargeted)
                    .dropDestination(for: DropItem.self, action: { items, _ in
                        for item in items {
                            switch item {
                            case .file(let id):
                                guard delegate.actions.contains(.move) else { continue }
                                if !delegate.canMove(id: id, newParentID: file.id) {
                                    break
                                } else {
                                    Task { try? await delegate.move(id:id, newParentID: file.id) }
                                }
                            case .url(let url):
                                guard delegate.actions.contains(.upload) else { continue }
                                delegate.upload([url], to: file.wrappedValue)
                            }
                        }
                        return true
                    }, isTargeted: {self.isTargeted = $0})
            }
            .if(delegate.actions.contains(.move) && delegate.canDrag(file: file.wrappedValue)) { content in
                content
                    .draggable(file.wrappedValue.id)
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


