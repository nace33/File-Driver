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
            let current  = delegate.tags.compactMap({$0.name}).joined()
            let eligible = delegate.selectedCase?.tags.filter({!current.ciContain($0.name)  }) ?? []
            LabeledContent {
                TextField("Tags", text:$tagText, prompt: Text("Add Tags"))
                    .labelsHidden()
                    .textInputSuggestions {
                        if tagText.count > 0 {
                            let matches = delegate.selectedCase?.tags.filter({$0.name.ciHasPrefix(tagText) && !current.ciContain($0.name)  }) ?? []
                            ForEach(matches) {  Text($0.name) .textInputCompletion($0.name) }
                        }
                    }
                    .onSubmit {
                        _ = addNewTag(tagText)
                        tagText = ""
                    }
            } label: {
                Menu("Tags") {
                    if eligible.count > 10 {
                        BOFSections(.menu, of: eligible , groupedBy: \.name, isAlphabetic: true) { letter in
                            Text(letter)
                        } row: { tag in
                            Button(tag.name) { addTag(tag)  }
                        }
                    } else {
                        ForEach(eligible.sorted(by: {$0.name.ciCompare($1.name)})) { tag in
                            Button(tag.name) { addTag(tag)  }
                        }
                    }
                }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(eligible.isEmpty ? .hidden : .visible)
                    .labelsHidden()
                    .fixedSize()
            }
            if delegate.tags.count > 0 {
                Flex_Stack(data: delegate.tags, alignment: .trailing) { tag in
                    let isExisting = tagIsInSpreadsheet(tag.id)
                    Text(tag.name)
                        .tokenStyle(color:isExisting ? .green : .orange,  style:.strike) {
                            removeTag(tag.id)
                        }
                }
            }
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
    
    func tagIsInSpreadsheet(_ id:Case.Tag.ID) -> Bool {
        delegate.selectedCase?.isInSpreadsheet(id, sheet: .tags) ?? false
    }
    func addTag(_ tag:Case.Tag) {
        if !delegate.tags.contains(where: {$0.id == tag.id }) {
            delegate.tags.append(tag)
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
    func removeTag(_ tagID:Case.Tag.ID) {
        delegate.tags.removeAll(where: {$0.id == tagID})
    }
}

#Preview {
    Form {
        Filer_Tags()
    }
        .formStyle(.grouped)
        .environment(Filer_Delegate())
}
