//
//  Filer.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/2/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct FileToCase_Suggestions : View {
    @Environment(FileToCase_Delegate.self) var delegate

    var cases : [Case] {
        let rootIDs = delegate.suggestions.compactMap({$0.root?.id}).unique()
        return delegate.cases.filter { rootIDs.contains($0.id)}
    }
    var body: some View {
        Section("Suggestions") {
            ForEach(cases, id:\.self) { aCase in
                let suggestions = delegate.suggestions.filter { $0.root?.id == aCase.id}
                FileToCase_Suggestions_Row(aCase: aCase, suggestions: suggestions)
            }
        }
        .listRowSeparator(.hidden)
    }
}



fileprivate struct FileToCase_Suggestions_Row : View {
    @Environment(FileToCase_Delegate.self) var delegate
    var aCase : Case
    var suggestions: [FolderSuggestion]
    var body: some View {
        HStack {
            Text(aCase.title)
         
            Spacer()
            if let suggestion = suggestions.first {
                if suggestions.count == 1 {
                    suggestionButton(suggestion)
                } else {
                    Menu(suggestion.name) {
                        ForEach(suggestions, id:\.self) {
                            suggestionButton($0)
                        }
                    }
                        .fixedSize()
                        .menuStyle(.borderlessButton)
                }
            }
        }
    }
    
    @ViewBuilder func suggestionButton(_ suggestion:FolderSuggestion) -> some View {
        Button(suggestion.name) {
            delegate.select(suggestion, in:aCase)
        }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
    }
}
