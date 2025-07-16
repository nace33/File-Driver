//
//  Filing_Sheet.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/9/25.
//

import SwiftUI
import BOF_SecretSauce


/*
struct Filing_Sheet: View {
    var items : [FileToCase_Item]
    init(_ items:[FileToCase_Item]) {
        self.items = items
        _selectedItem = State(initialValue: items.first ?? FileToCase_Item(printURL: URL(string:"about:blank")!, filename: "No Item Found"))
    }
    @State private var loader         = VLoader_Item()
    @State private var fileToDelegate = FileToCase_Delegate()
    @State private var showDriveSelector = false
    
    @State private var selectedItem : FileToCase_Item
    @Environment(\.dismiss) var dismiss
    @AppStorage(BOF_Settings.Key.filingAutoRename.rawValue)  var automaticallyRenameFiles: Bool = true
    
    var body: some View {
        VStackLoacker(loader: $loader) {
            cancel()
        } content: {
            preview()
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task(id:items) { newItemsReceived() }
            .inspector(isPresented: .constant(showInspector)) {
                FileToCase(items,actions: [.fileLater, .cancel, .addToCase]) { isFiling in
//                    self.isFiling = isFiling
                } filed: { filedItems in
//                    justFiled($0)
                } canceled: {
                    cancel()
                }
                    .inspectorColumnWidth(min:400, ideal: 400, max:600)
            }
            .onChange(of: showInspector) { oldValue, newValue in
                loader.isLoading = false
            }
            .onChange(of: selectedItem.error as? NSError) { oldValue, newValue in
                loader.isLoading = false
                loader.error = newValue
            }
            .onChange(of: selectedItem.progress) { oldValue, newValue in
                loader.progress = newValue
            }
    }
    var showInspector : Bool {
        guard items.count > 0 else { return false }
        return selectedItem.localURL != nil || selectedItem.file != nil
    }
}


//MARK: - Preview
fileprivate extension Filing_Sheet {
    @ViewBuilder func preview() -> some View {
        HStack {
            Menu(selectedItem.filename) {
                ForEach(items, id:\.self) { item in
                    Button(item.filename) { selectedItem = item }
                }
                
                if items.count > 0 {
                    Divider()
                }
                Button("Cancel") { cancel() }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(items.count == 1 ? .hidden : .visible)
        }
        .padding(10)
        
        preview(selectedItem)
    }
    @ViewBuilder func preview(_ item:FileToCase_Item) -> some View {
        if let error = item.error {
            itemErrorView(error)
        }
        else if let localURL = item.localURL {
            QL_View(fileURL: localURL, style: .normal)
        } else if let file = item.file {
            Drive_Preview(file: file)
        } else {
            Text("Cannot locate filing item.")
        }
    }
    @ViewBuilder func itemErrorView(_ error:Error) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    Text(error.localizedDescription)
                    cancelButton
                }
                Spacer()
            }
            Spacer()
        }
    }
}

//MARK: - Toolbar
fileprivate extension Filing_Sheet {
    @ViewBuilder var toolbarActionView : some View {
        HStack {
            saveToMenu
            Spacer()
            cancelButton
            addToCaseButton
        }
    }
    
    //Save To
    var canSaveTo : Bool {
        guard !loader.isLoading else { return false }
        return true
    }
    @ViewBuilder var saveToMenu : some View {
        Menu("Save To") {
            
        }
            .disabled(!canSaveTo)
    }
    
    //Cancel
    func cancel() {
        for item in self.items {
            if let localURL = item.localURL {
                try? FileManager.default.trashItem(at: localURL, resultingItemURL: nil)
            }
        }
        dismiss()
    }
    @ViewBuilder var cancelButton : some View {
        Button("Cancel") { cancel() }
            .foregroundStyle(.red)
            .buttonStyle(.link)
            .padding(.trailing, 8)
    }
    
    
    //Add To Case
    var canAddToCase : Bool {
        guard !loader.isLoading   else { return false }
        guard !fileToDelegate.isFiling  else { return false }
        guard !fileToDelegate.isLoading else { return false }
        guard items.filter({$0.filename.isEmpty}).isEmpty else { return false }
        return true
    }
    func addToCase() {
        
    }
    @ViewBuilder var addToCaseButton : some View {
        Button("Add to Case") {
            addToCase()
        }
            .buttonStyle(.borderedProminent)
            .disabled(!canAddToCase)
    }
}


//MARK: - Itemss
fileprivate extension Filing_Sheet {
    func newItemsReceived() {
        selectedItem = items.first ?? FileToCase_Item(printURL: URL(string:"about:blank")!, filename: "No Item Found")
        loader.isLoading = !showInspector
    }

    func processDownloaded(_ url:URL, for item:FileToCase_Item) {
        loader.progress = 0
        item.localURL = url
        if automaticallyRenameFiles,
           let renamedURL = try? AutoFile_Rename.autoRenameLocalFile(url: url, thread:item.localURL?.pdfGmailThread) {
            item.localURL = renamedURL
        }
    }

}
*/
