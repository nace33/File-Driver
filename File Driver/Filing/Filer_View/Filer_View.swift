//
//  Filer_View.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/21/25.
//

import SwiftUI


struct Filer_View: View {
    @State private var delegate : Filer_Delegate
    let items : [Filer_Item]
    init(items:[Filer_Item], delegate: Filer_Delegate = .init()) {
        self.items = items
        _delegate = State(initialValue: delegate)
    }
    
    var body: some View {

        VStackLoacker(alignment:.leading, spacing: 0, loader: $delegate.loader) {
            delegate.clearError()
        } header: {
            Filer_Header()
            Divider()
        } content: {
            if delegate.items.isEmpty {
                messageView("Nothing items to file.")
            }
            else if delegate.items.allSatisfy({$0.status == .filed}) {
                messageView("Success!")
            }
            else if delegate.canShowForm {
                Filer_Form()
                    .onAppear() {
                        delegate.setFilingState(.formPresented(delegate.selectedCase, delegate.selectedFolder))
                    }
            } else if delegate.selectedMode == .cases && delegate.selectedCase == nil {
                Filer_CaseList()
            } else if delegate.selectedMode == .contacts && delegate.selectedContact == nil {
                Filer_ContactList()
            } else {
                Filer_FolderList()
            }
        } footer: {
            Divider()
            Filer_Footer()
        }
            .environment(delegate)
            .background(.background)
            .task {
                await delegate.load()
            }
            .task(id:items) {
                delegate.items = items
            }
    }
    
    @ViewBuilder func messageView(_ text:String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
}

#Preview {
    Filer_View(items: [])
        .environment(Google.shared)
}



