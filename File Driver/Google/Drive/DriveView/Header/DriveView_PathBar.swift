//
//  Google.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//


import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce


struct DriveView_PathBar<Action:View> : View {
    let title : String
    @Environment(DriveDelegate.self) var delegate
    let tail : (() -> Action)?
    
    init(_ title: String,  @ViewBuilder actions: @escaping() -> Action) {
        self.title = title
        self.tail = actions
    }
    init(_ title: String) where Action == EmptyView {
        self.title = title
        self.tail = nil
    }
    let minWidth : CGFloat = 30.0
    

    
    var body: some View {
        HStack {
            if !title.isEmpty, delegate.rootID == nil {
                Group {
                    if delegate.stack.isNotEmpty {
                        Button(title) {
                            delegate.removeAllFromStack()
                        }
                        .frame(minWidth:minWidth)
                        Image(systemName: "chevron.right")
                    } else {
                        Button(title) {
                            delegate.refresh()
                        }
                        .frame(minWidth:minWidth)
                    }
                }
            }
            ForEach(Array(delegate.stack.enumerated()), id: \.offset) { index, element in
                Button(element.title) {
                    if index+1 < delegate.stack.count  {
                        delegate.removeRangeFromStack(index+1..<delegate.stack.count)
                    } else {
                        delegate.refresh()
                    }
                }
                    .frame(minWidth:minWidth)
                    .layoutPriority(Double(index))
                    .dropDestination(for: GTLRDrive_File.ID.self) { items, location in
                        processMoveItems(items, to:element.id)
                    }
//                    .disabled(index+1 == delegate.stack.count )
                if index+1 < delegate.stack.count {
                    Image(systemName: "chevron.right")
                }
            }
            if let tail {
                tail()
                    .layoutPriority(Double(delegate.stack.count) + 1.0)
            }
        }
    }
    
    func processMoveItems(_ itemIDs:[GTLRDrive_File.ID], to parentID:GTLRDrive_File.ID) -> Bool {
        let satisfy = itemIDs.allSatisfy { id in
            delegate.canMove(id: id, newParentID: parentID)
        }
        guard satisfy else { return false }
        Task {
            try? await delegate.move(ids: itemIDs, newParentID: parentID)
        }
        return true
    }
}

