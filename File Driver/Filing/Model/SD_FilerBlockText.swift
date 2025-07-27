//
//  RenameWordBlock.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/23/25.
//

import Foundation
import SwiftData

@Model
final class FilerBlockText: Identifiable {
    var text : String = ""
    var categoryIntValue : Int = 0
    var category  : FilerBlockText.Category {
        get { FilerBlockText.Category(rawValue: categoryIntValue) ?? .exact }
        set { categoryIntValue = newValue.rawValue }
    }
    enum Category: Int {
        case contains, exact
    }
    init(text: String, category: FilerBlockText.Category) {
        self.categoryIntValue = category.rawValue
        self.text = text
    }
    
    func isBlocked(_ string:String) -> Bool {
        switch category {
        case .exact:
            return string.lowercased() == text.lowercased()
        case .contains:
            return string.localizedCaseInsensitiveContains(text)
        }
    }
}

@MainActor
extension FilerBlockText {
    static var blockedWords : [FilerBlockText] {
        let descriptor = FetchDescriptor<FilerBlockText>()
        return BOF_SwiftData.shared.fetch(descriptor) ?? []
    }
    static func isBlocked(_ string:String) -> Bool {
        blockedWords.filter ( { block in
            block.isBlocked(string)
        })
            .count > 0
    }

    static func subtractBlockedWords(_ strings:Set<String>) -> Set<String>{
        var found : Set<String> = []
        for string in strings {
            for blockedWord in blockedWords {
                if blockedWord.isBlocked(string) {
                    found.insert(string)
                    break
                }
            }
        }
        return strings.subtracting(found)
    }

    static func foundBlockedWords<T>(items:[T], textKey:KeyPath<T,String>) -> [T] {
        let blocked = blockedWords
        return items.filter { item in
            let string = item[keyPath: textKey]
            for block in blocked {
                if block.isBlocked(string) {
                    return true
                }
            }
            return false
        }
    }
    static func filterBlockedWords<T>(items:[T], textKey:KeyPath<T, String>) -> [T]  {
        let blocked = blockedWords
        return items.filter { item in
            let string = item[keyPath: textKey]
            for block in blocked {
                if block.isBlocked(string) {
                    return false
                }
            }
            return true
        }
    }
    
    static func removeBlockedWords(from string:String) -> String {
        let blocked = blockedWords
        var str = string
        for block in blocked {
            str = str.replacingOccurrences(of: block.text, with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
        }
        return str
    }

}

  

