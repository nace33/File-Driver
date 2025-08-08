//
//  Filer_Tags.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/23/25.
//

import SwiftUI
import BOF_SecretSauce

struct Filer_Tags: View {
    @Environment(Filer_Delegate.self) var delegate
    @State private var tagText  = ""
    @AppStorage(BOF_Settings.Key.filingFormTagMatch.rawValue)              var allowTagMatch       : Bool = true

    var body: some View {
        Section {
            let eligible = delegate.selectedCase?.tags ?? []
            FormTokensPicker(title: "Tags", items: Bindable(delegate).tags, allItems:eligible, titleKey: \.name, tokenColor:.green, altColor:.orange, create:  { createString in
                addNewTag(createString)
            })
        }
            .task(id:delegate.items) {
                loadFilerItemTags()
            }
            .onChange(of: allowTagMatch) { oldValue, newValue in
                loadFilerItemTags()
            }
    }
    
    func loadFilerItemTags() {
        delegate.tags.removeAll()
        
        guard allowTagMatch else { return }
        let existingTags = delegate.selectedCase?.tags ?? []

        var strings : Set<String> = []
        for item in delegate.items {
            strings.formUnion(item.lowercasedSearchStrings)
        }
        let searchString = strings.joined(separator: " ")

        delegate.tags = existingTags.filter {
            searchString.contains($0.name.lowercased())
        }
    }
    func addNewTag(_ text:String) -> Case.Tag {
        if let existing = delegate.selectedCase?.tags.first(where: {$0.name.lowercased() == text.lowercased()}) {
            addTag(existing)
            return existing
        } else {
            let newTag = Case.Tag(id: UUID().uuidString, name: text, note: nil)
            addTag(newTag)
            return newTag
        }
    }
   
    func addTag(_ tag:Case.Tag) {
        if !delegate.tags.contains(where: {$0.id == tag.id }) {
            delegate.tags.append(tag)
        }
    }
}

#Preview {
    Form {
        Filer_Tags()
    }
        .formStyle(.grouped)
        .environment(Filer_Delegate())
}
