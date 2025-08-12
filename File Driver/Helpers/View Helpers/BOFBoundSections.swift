//
//  BOFBoundSections.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/8/25.
//

import SwiftUI

public struct BOFBoundSections<T:Identifiable & Hashable, V:View, G:Hashable & Comparable> : View {
    var items : Binding<[T]>
    var key   : KeyPath<T, G>
    var header : (G) -> Text
    var row     : (Binding<T>) -> V
    var sections : [G]
    let isAlphabetic : Bool
    public init(of items: Binding<[T]>, groupedBy groupKey: KeyPath<T, G>, @ViewBuilder header:@escaping (G) -> Text, @ViewBuilder row:@escaping (Binding<T>) -> V) {
        self.items = items
        self.key = groupKey
        self.header = header
        self.row = row
        isAlphabetic = false
        self.sections = items.compactMap { $0.wrappedValue[keyPath:groupKey] }.unique().sorted()
    }
    public init(of items: Binding<[T]>, groupedBy groupKey: KeyPath<T, G>, isAlphabetic:Bool = false, @ViewBuilder header:@escaping (G) -> Text, @ViewBuilder row:@escaping (Binding<T>) -> V) where G == String {
        self.items = items
        self.key = groupKey
        self.header = header
        self.row = row
        self.isAlphabetic = isAlphabetic
        if isAlphabetic {
           // self.sections = (0...25).compactMap { $0.letter }
            //Using above means any non-alphabetic filename is never matched
            self.sections = items.compactMap { $0.wrappedValue[keyPath:groupKey][0]}.unique().sorted(by: {$0.uppercased() < $1.uppercased()})
        } else {
            self.sections = items.compactMap { $0.wrappedValue[keyPath:groupKey] }.unique().sorted(by: {$0.uppercased() < $1.uppercased()})
        }
    }
    
    func matches(for section:G) -> Binding<[T]> {
        return Binding {
            if isAlphabetic, let letter = section as? String {
                return items.wrappedValue.filter {
                    if let value = $0[keyPath:key] as? String {
                        return value.lowercased().hasPrefix(letter.lowercased())
                    } else {
                        return false
                    }
                }
            }
            return items.wrappedValue.filter { $0[keyPath:key] == section }
        } set: { newValue in
            
        }
    }
    public var body: some View {
        ForEach(sections, id:\.self) { section in
            let matches = matches(for: section)
            if !matches.isEmpty {
                Section {
                    ForEach(matches) { match in
                        row(match)
                    }
                } header: {
                    header(section)
                }
            }
        }
    }
}
