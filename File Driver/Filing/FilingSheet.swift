//
//  FilingSheet.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/23/25.
//

import SwiftUI
import BOF_SecretSauce

struct FilingSheet: View {
    let showPreview : Bool
    let modes : [Filer_Delegate.Mode]
    let items : [Filer_Item]
    let state : (Filer_Delegate.FilingState) -> Void
    init(showPreview:Bool = true, delegate:Filer_Delegate, items: [Filer_Item], state:((Filer_Delegate.FilingState) -> Void)? = nil ) {
        self.showPreview = showPreview
        _filerDelegate = State(initialValue: delegate)
        self.modes = delegate.modes
        self.items = items
        self.state = state ?? { _ in }
    }
    init(showPreview:Bool = true,
         modes: [Filer_Delegate.Mode] = [.cases, .contacts, .folders],
         items: [Filer_Item],
         actions:[Filer_Delegate.Action] = Filer_Delegate.Action.sheetActions,
         state:((Filer_Delegate.FilingState) -> Void)? = nil ) {
        
        self.showPreview = showPreview
        self.modes = modes
        self.items = items
        _filerDelegate = State(initialValue: Filer_Delegate(modes: modes, actions:actions))
        self.state = state ?? { _ in }
    }
    
    @State private var filerDelegate : Filer_Delegate
    @State private var selectedItem : Filer_Item?
    
    var body: some View {
        HSplitView {
            if showPreview {
                FilePreview(selectedItem)
                    .frame(minWidth:350, maxHeight: .infinity)
            }
            
            Filer_View(items:items, delegate: filerDelegate)
                .frame(minWidth: 350, maxHeight: .infinity)
        }
            .task(id:items) {
                selectedItem = items.first
            }
            .onChange(of: filerDelegate.filingState, { oldValue, newValue in
                self.state(newValue)
            })
            .presentationSizing(.fitted) // Allows resizing, sizes to content initially
            .frame(idealWidth: showPreview ? 800 : 500, minHeight:400, idealHeight: showPreview ? 600 : 400) //
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
            Text(filerDelegate.loader.isLoading ? "Generating Preview" : "No Preview Available")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }
}




#Preview {
    FilingSheet(modes:[.cases], items:[])
}
