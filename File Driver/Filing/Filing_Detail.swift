//
//  Filing_Detail.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import SwiftUI

struct Filing_Detail: View {
//    @Environment(DriveDelegate.self) var driveDelegate
    @State private var isFiling: Bool = false
    
    @State private var filerDelegate = Filer_Delegate( actions:Filer_Delegate.Action.inlineActions)
    var body: some View {
        Filer_View(items: [], delegate: filerDelegate)
//            .onChange(of: driveDelegate.selection, { _, _ in
//                Task {
//                    let items = driveDelegate.selection
//                                             .sorted(by: {$0.title.ciCompare($1.title)})
//                                             .compactMap({Filer_Item(file:$0)})
//                    filerDelegate.items = items
//                }
//            })
//        
//            .onChange(of: filerDelegate.filingState, { _, _ in
//                switch filerDelegate.filingState {
//                case .isFiling:
//                    isFiling = true
//                case .filed(let items, let allFiled):
//                    isFiling = false
//                    processFiled(items, allFiled)
//                default:
//                    isFiling = false
//                }
//            })
    }
    
//    func processFiled(_ items:[Filer_Item], _ allFiled:Bool) {
//        driveDelegate.removeFiles(items.compactMap(\.file?.id))
//        if allFiled {
//            filerDelegate.reset(reload:false)
//            if let firstFile = driveDelegate.files.first {
//                driveDelegate.selection = [firstFile]
//            }
//        }
//    }
}

#Preview {
    Filing_Detail()
}
