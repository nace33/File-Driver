//
//  Filer_Filenames.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/23/25.
//

import SwiftUI

struct Filer_Filenames: View {
    @Environment(Filer_Delegate.self) var delegate
    @State private var showRenameSheet = false
    
    
    var body: some View {
        
        Section {
            LabeledContent {
                VStack {
                    ForEach(Bindable(delegate).items) { $item in
                        TextField("Filename", text: $item.filename, prompt: Text("Enter filename here"), axis: .vertical)
                            .labelsHidden()
                        if item != delegate.items.last {
                            Divider()
                        }
                    }
                }
            } label: {
                Menu("Filename\(delegate.items.count == 1 ? "" : "s")") {
                    Button("Reset filename\(delegate.items.count == 1 ? "" : "s")") { resetFilenames() }
                    if delegate.items.count > 1 {
                        Button("Rename In Sequence") { showRenameSheet = true }
                    }
                }
                    .fixedSize()
                    .menuStyle(.borderlessButton)
                    .menuIndicator(hasFilenameToReset || delegate.items.count > 1 ? .visible : .hidden)
            }
        }
        .sheet(isPresented: $showRenameSheet) {
            Renamer(title: "Rename Files", items: delegate.items, key: \.filename, canReorder: false) { items in
                for item in items {
                    if let filingIndex = delegate.items.firstIndex(of: item.item) {
                        delegate.items[filingIndex].filename = item.string
                    }
                }
            }
        }
 
    }
    var hasFilenameToReset : Bool {
        !delegate.items.allSatisfy { item in
            item.file?.titleWithoutExtension == item.filename
        }
    }
    func resetFilenames() {
        for item in delegate.items {
            item.filename = item.file?.titleWithoutExtension ?? ""
        }
    }
}

#Preview {
    Form {
        Filer_Filenames()
    }
        .formStyle(.grouped)
        .environment(Filer_Delegate())
}
