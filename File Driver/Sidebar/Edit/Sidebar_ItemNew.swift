//
//  SidebarItem.swift
//  TableTest
//
//  Created by Jimmy on 4/3/25.
//


import SwiftUI
import SwiftData

struct SidebarItem_New : View {
    @State private var title: String = ""
    @State private var urlString  : String = ""
    @Query(sort:\Sidebar_Item.order) private var items: [Sidebar_Item]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                TextField("URL", text: $urlString)
                LabeledContent("") {
                    Text(checkForError?.localizedDescription ?? " ").font(.caption).foregroundStyle(.secondary)
                }
            } header: {
                Text("Add New Item").font(.title)
            } footer: {
                
                HStack {
                    Spacer()
                    #if os(macOS)
                    Button("Cancel") {dismiss() }
                    #endif
                    Button("Add To Sidebar") {addItem() }.disabled(checkForError != nil)
                }
            }
        }
            .formStyle(.grouped)
    }
 

    
    private func addItem() {
        withAnimation {
            guard let url = URL(string:urlString) else { return }
            
            let max = items.last?.order ?? 0

            let newItem = Sidebar_Item(url: url, title: title, category:.user, order: max + 1)
            modelContext.insert(newItem)
            dismiss()
        }
    }
    
    
}

import BOF_SecretSauce
fileprivate
extension SidebarItem_New {
    var checkForError : Create_Error? {
        do throws(Create_Error){
            guard !title.isEmpty else { throw Create_Error.noTitle  }
            guard items.filter({ $0.title.lowercased() == title.lowercased()}).count == 0 else { throw Create_Error.duplicateTitle }
            guard urlString.isValidURL else { throw Create_Error.invalidURL }
            guard items.filter({ $0.url.absoluteString.lowercased() == urlString.lowercased() }).count == 0 else { throw Create_Error.duplicateURL }
            return nil
        } catch {
            return error
        }
    }
    enum Create_Error : LocalizedError {
        case noTitle
        case duplicateTitle
        case invalidURL
        case duplicateURL
        var localizedDescription: String {
            switch self {
            case .noTitle:
                "No title provided."
            case .duplicateTitle:
                "Title already exists."
            case .invalidURL:
                "Not a valid URL"
            case .duplicateURL:
                "URL already exists"
            }
        }
    }
}
