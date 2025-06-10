//
//  Sidebar_ItemEdit.swift
//  TableTest
//
//  Created by Jimmy Nasser on 4/4/25.
//

import SwiftUI
import SwiftData
import BOF_SecretSauce

struct SidebarItem_Edit : View {
    var item : Sidebar_Item
    init(_ item: Sidebar_Item) {
        self.item = item
    }
    @Environment(\.dismiss) var dismiss
    @State private var urlString : String = ""
    
    var body: some View {
        VStack {
            Text("Edit Sidebar Item").font(.title)
            Divider()
            Form {
                TextField("Name", text: Bindable(item).title)
                    .onSubmit {
                        if item.isDefault || item.isGroup {
                            dismiss()
                        }
                    }
                if !item.isDefault && !item.isGroup {
                    TextField("URL", text: $urlString)
                        .onSubmit {
                            if let url = urlString.validURL {
                                item.url = url
                            }
                        }
                    
                    Button("Download Favicon") { item.downloadFavicon() }
                    #if os(macOS)
                    if let data = item.iconData,
                       let image = NSImage(data: data) {
                        Image(nsImage:image )
                    }
                    #elseif os(iOS)
                    if let data = item.iconData,
                       let image = UIImage(data: data) {
                        Image(uiImage:image )
                    }
                    #endif
                }
                
            }
   
        }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss()  }
                        .buttonStyle(.borderedProminent)
                }
            }
      }

}

#Preview {
    @Previewable @State var item : Sidebar_Item = .init(url: Sidebar_Item.Category.cases.defaultURL, title: "Cases", category: .cases, order: 0)
    SidebarItem_Edit(item)
        .modelContainer(for: Sidebar_Item.self, inMemory: true)

}
