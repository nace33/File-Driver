//
//  FlexFormLabel.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/4/25.
//

import SwiftUI
import BOF_SecretSauce
/*
public
struct FormTokensPicker<T : Identifiable & Hashable> : View {
    private let title : String
    private let items: [T]
    private let allItems : [T]
    private let titleKey  : KeyPath<T, String>
    private var color  : ((T) -> Color)? = nil
    private var create : ((String) -> Void)? = nil
    private let append : (T) -> Void
    private let remove : (T) -> Void
    
    public init(title: String, items:[T], allItems: [T], titleKey: KeyPath<T, String>, tokenColor: ((T) -> Color)? = nil, create: ((String) -> ())? = nil, append:@escaping(T) -> Void, remove:@escaping(T) -> Void) {
        self.title = title
        self.items = items
        self.allItems = allItems
        self.titleKey = titleKey
        self.color = tokenColor
        self.create = create
        self.append = append
        self.remove = remove
    }
    public init(title: String, items:[T], allItems: [T], titleKey: KeyPath<T, String>, tokenColor: Color, altColor:Color? = nil, create: ((String) -> ())? = nil, append:@escaping(T) -> Void, remove:@escaping(T) -> Void) {
        self.title = title
        self.items = items
        self.allItems = allItems
        self.titleKey = titleKey
        self.color = { item in
            if allItems.contains(item) { tokenColor }
            else { altColor ?? tokenColor }
        }
        self.create = create
        self.append = append
        self.remove = remove
    }
    
    @State private var text : String = ""
    public var body: some View {
        LabeledContent {
            VStack(alignment:.trailing, spacing:10) {
                if let create {
                    TextField(title, text:$text, prompt: Text("Add \(title)"))
                        .multilineTextAlignment(.trailing)
                        .labelsHidden()
#if os(macOS)
                        .textInputSuggestions {
                            if text.count > 0 {
                                let matches = allItems.filter({$0[keyPath: titleKey].ciHasPrefix(text) && !items.contains($0)  })
                                ForEach(matches) {  Text($0[keyPath: titleKey]) .textInputCompletion($0[keyPath: titleKey]) }
                            }
                        }
#endif
                        .onSubmit {
                            if let existing = allItems.first(where:{ $0[keyPath: titleKey] == text }) { append(existing)}
                            else { create(text) }
                            text = ""
                        }
                }
                if items.count > 0 {
                    Flex_Stack(data: items , alignment:.trailing) { item in
                        Text(item[keyPath: titleKey])
                            .textSelection(.disabled)
                            .tokenStyle(color:color?(item) ?? .blue, style:.strike) {
                                remove(item)
                            }
                    }
                }
            }
        } label: {
            let existingIDs = Set(items.map(\.id))
            let remainingItems = allItems.filter { !existingIDs.contains($0.id) }
                                         .sorted(by: {$0[keyPath: titleKey] < $1[keyPath: titleKey]})
            Menu {
                if remainingItems.count > 8 {
                    BOFSections(.menu, of: remainingItems, groupedBy:titleKey, isAlphabetic: true) { header in
                        Text(header)
                    } row: { item in
                        Button(item[keyPath: titleKey]){append(item)}
                    }
                } else {
                    ForEach(remainingItems) { item in Button(item[keyPath: titleKey]){append(item)}}
                }
            } label: {
                Text(title)
            }
            .offset(x:-4)
            .menuStyle(.borderlessButton)
            .menuIndicator(remainingItems.isEmpty ? .hidden : .visible)
            .labelsHidden()
        }
            .labeledContentStyle(.fixedWidth)
    }
}
*/
public
struct FormTokensPicker<T : Identifiable & Hashable> : View {
    private let title : String
    private let items: Binding<[T]>
    private let allItems : [T]
    private let titleKey  : KeyPath<T, String>
    private var color  : ((T) -> Color)? = nil
    private var create : ((String) -> T?)? = nil
    
    public init(title: String, items: Binding<[T]>, allItems: [T], titleKey: KeyPath<T, String>, tokenColor: ((T) -> Color)? = nil, create: ((String) -> (T)?)? = nil) {
        self.title = title
        self.items = items
        self.allItems = allItems
        self.titleKey = titleKey
        self.color = tokenColor
        self.create = create
    }
    public init(title: String, items: Binding<[T]>, allItems: [T], titleKey: KeyPath<T, String>, tokenColor: Color = .blue, altColor:Color? = nil, create: ((String) -> (T)?)? = nil) {
        self.title = title
        self.items = items
        self.allItems = allItems
        self.titleKey = titleKey
        self.color = { item in
            if allItems.contains(item) { tokenColor }
            else { altColor ?? tokenColor }
        }
        self.create = create
    }
    @State private var text : String = ""
    
    public var body: some View {
        LabeledContent {
            VStack(alignment:.trailing, spacing:10) {
                if let create {
                    TextField(title, text:$text, prompt: Text("Add \(title)"))
                        .multilineTextAlignment(.trailing)
                        .labelsHidden()
#if os(macOS)
                        .textInputSuggestions {
                            if text.count > 0 {
                                let matches = allItems.filter({$0[keyPath: titleKey].ciHasPrefix(text) && !items.wrappedValue.contains($0)  })
                                ForEach(matches) {  Text($0[keyPath: titleKey]) .textInputCompletion($0[keyPath: titleKey]) }
                            }
                        }
#endif
                        .onSubmit {
                            if text.isEmpty { }
                            else {
                                if let existing = allItems.first(where:{ $0[keyPath: titleKey] == text }) {
                                    append(existing)
                                }
                                else {
                                    if items.wrappedValue.filter({$0[keyPath: titleKey].ciContain(text)}).count == 0, let newItem = create(text) {
                                        append(newItem)
                                    }
                                }
                                text = ""
                            }
                        }
                }
                
                if items.count > 0 {
                    Flex_Stack(data: items.wrappedValue , alignment:.trailing) { item in
                        Text(item[keyPath: titleKey])
                            .textSelection(.disabled)
                            .tokenStyle(color:color?(item) ?? .blue, style:.strike) {
                               remove(item)
                            }
                    }
                } else if create == nil {
                    Text("No \(title)")
                        .frame(maxWidth:.infinity, alignment:.trailing)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            let existingIDs = Set(items.wrappedValue.map(\.id))
            let remainingItems = allItems.filter { !existingIDs.contains($0.id) }
                                         .sorted(by: {$0[keyPath: titleKey] < $1[keyPath: titleKey]})
            Menu {
                if remainingItems.count > 8 {
                    BOFSections(.menu, of: remainingItems, groupedBy:titleKey, isAlphabetic: true) { header in
                        Text(header)
                    } row: { item in
                        Button(item[keyPath: titleKey]){append(item)}
                    }
                } else {
                    ForEach(remainingItems) { item in Button(item[keyPath: titleKey]){append(item)}}
                }
            } label: {
                Text(title)
            }
            .offset(x:-4)
            .menuStyle(.borderlessButton)
            .menuIndicator(remainingItems.isEmpty ? .hidden : .visible)
            .labelsHidden()
        }
            .labeledContentStyle(.fixedWidth)
    }
    
    private func append(_ item: T) {
        if !items.wrappedValue.contains(item) {
            print("\tAppending: \(item.id)")
            items.wrappedValue.append(item)
        }
    }
    private func remove(_ item:T) {
        items.wrappedValue.removeAll(where: {$0.id == item.id})
    }
}
