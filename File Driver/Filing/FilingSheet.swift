//
//  FilingSheet.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/23/25.
//

import SwiftUI
import BOF_SecretSauce

struct FilingSheet: View {
    let items : [Filer_Item]

    
    @State private var filerDelegate = Filer_Delegate(mode: .cases, actions:Filer_Delegate.Action.sheetActions)
    @State private var selectedItem : Filer_Item?
    @State private var showPreview = false
    
    var body: some View {
        HSplitView {
            FilePreview(selectedItem)
                .frame(minWidth:350, maxHeight: .infinity)
            
            Filer_View(items:items, delegate: filerDelegate)
                .frame(minWidth: 350, maxHeight: .infinity)
        }
            .task(id:items) {
                selectedItem = items.first
            }
    }
  


    @ViewBuilder func FilePreview(_ item:Filer_Item?) -> some View {
        if let item, item.category == .localURL, let localURL = item.localURL {
            if items.count > 1 {
                HStack {
                    Menu(selectedItem?.filename ?? "Select Item") {
                        ForEach(items, id:\.self) { item in
                            Button(item.filename) { selectedItem = item }
                        }
                    }
                        .menuStyle(.borderlessButton)
                        .menuIndicator(items.count == 1 ? .hidden : .visible)
                }
                .padding(.top, 10)
                .padding(.bottom, 4)
            }
            QL_View(fileURL:localURL, style: .normal)
        } else {
            Text("Generating Preview").foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
//            ContentUnavailableView("Generating Preview", systemImage:"document.badge.clock")
        }
    }
}

#Preview {
    FilingSheet(items:[])
}
