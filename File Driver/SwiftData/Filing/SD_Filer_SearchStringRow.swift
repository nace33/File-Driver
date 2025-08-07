//
//  SD_Filer_SearchStringRow.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/29/25.
//

import SwiftUI
import SwiftData
struct SD_Filer_SearchStringRow: View {
    let searchString : FilerSearchString
    @Environment(\.modelContext) var context
    @Query var blockedWords: [FilerBlockText]
    @Query var searchStrings: [FilerSearchString]

    func isBlocked(_ string:FilerSearchString) -> Bool {
        blockedWords.filter ( { block in
            block.isBlocked(string.text)
        })
            .count > 0
    }
    
    var body: some View {
        Text(searchString.text)
            .foregroundStyle(isBlocked(searchString) ? .red : .primary)
            .contextMenu {
                rightClickMenu
            }
    }
    
    @ViewBuilder var rightClickMenu : some View {
        Text(searchString.itemID)
        let otherMatches = searchStrings.filter { $0.itemID == searchString.itemID  && $0 != searchString}
        ForEach(otherMatches) { otherMatch in
            Text(otherMatch.category.title + ":\t" + otherMatch.text)
        }
        let bw = blockedWords.filter ( { block in
            block.isBlocked(searchString.text)
        })
        if bw.count > 0 {
            if bw.count == 1, let b = bw.first {
                Text("Blocked because \( b.category == .exact ? "of exact match to" : "text contains") '\(b.text)'")
                Button("Remove Block") { remove(b)}
            } else {
                Menu("Blocked Because:") {
                    ForEach(bw) { b in
                        switch b.category {
                        case .exact:
                            Menu("\tExact match of '\(b.text)'") { Button("Remove Block") { remove(b)}}
                        case .contains:
                            Menu("\tContains text: '\(b.text)'") { Button("Remove Block") { remove(b)}}
                        }
                    }
                }
            }
        } else {
            Menu("Block") {
                Button("Exact Block") { createBlockedWord(category: .exact)}
                Button("Contains Block") { createBlockedWord(category: .contains)}

            }
        }
        Divider()
        Button("Delete") { context.delete(searchString) }

    }
    
    func remove(_ block:FilerBlockText) {
        context.delete(block)
    }
    func createBlockedWord(category:FilerBlockText.Category)  {
        let newBlock = FilerBlockText(text: searchString.text, category: category)
        context.insert(newBlock)
    }

}


