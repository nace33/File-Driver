//
//  TextField_Suggestions.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import SwiftUI

struct TextField_Suggestions: View {
    let label : String
    @Binding var text : String
    let prompt : Text?
    let style : TextField_Suggestions.Style?
    let suggestions : [String]
    @AppStorage(BOF_Settings.Key.textSuggestionStyle.rawValue) var defaultStyle : TextField_Suggestions.Style = .menu

    var theStyle : TextField_Suggestions.Style {
        style ?? defaultStyle
    }
    var body: some View {
        Group {
            switch theStyle {
            case .inline:
                textFieldInlineSuggestions
            case .menu:
                HStack {
                    textField
                    menu
                        .disabled(!hasSuggestions)
                }
            case .both:
                HStack {
                    textFieldInlineSuggestions
                    menu
                        .disabled(!hasSuggestions)
                }
            }
        }
            .textSelection(.disabled)
            .contextMenu {
                if style == nil {
                    TextField_Suggestions.Settings()
                }
            }
    }
}

//MARK: - Init
extension TextField_Suggestions {
    init(_ label:String, text:Binding<String>, prompt:Text? = nil, style : TextField_Suggestions.Style? = nil, suggestions:[String] ) {
        self.label = label
        _text = text
        self.prompt = prompt
        self.style = style
        self.suggestions = suggestions
    }
}


//MARK: - Properties
extension TextField_Suggestions {
    var hasSuggestions : Bool {
        !suggestions.isEmpty
    }
    var filteredSuggestions : [String] {
        guard !text.isEmpty else {
            return suggestions
        }
        return suggestions.filter { $0.ciHasPrefix(text) && $0.lowercased() != text.lowercased() }
    }
}



//MARK: - Properties
extension TextField_Suggestions {
    @ViewBuilder var textField : some View {
        TextField(label, text: $text, prompt: prompt)

    }
    @ViewBuilder var textFieldInlineSuggestions : some View {
        TextField(label, text: $text, prompt: prompt)
            .textInputSuggestions {
                ForEach(filteredSuggestions, id:\.self) { suggestion in
                    Text(suggestion)
                        .textInputCompletion(suggestion)
                }
            }
    }
    @ViewBuilder var menu : some View {
        Menu("") {
            ForEach(suggestions, id:\.self) { suggestion in
                Button(suggestion) { text = suggestion}
            }
        }
            .fixedSize()
            .menuStyle(.borderlessButton)
    }
}



//MARK: - Settings
extension TextField_Suggestions {
    enum Style : String, CaseIterable, Codable {
        case inline, menu, both
    }
    struct Settings : View {
        @AppStorage(BOF_Settings.Key.textSuggestionStyle.rawValue) var defaultStyle : TextField_Suggestions.Style = .menu
        var body: some View {
            Picker("Suggestion Style", selection: $defaultStyle) {
                ForEach(TextField_Suggestions.Style.allCases, id:\.self) { style in Text(style.rawValue.capitalized)}
            }
        }
    }
}

//MARK: - Preview
#Preview {
    @Previewable @State var text = ""
    let suggestions : [String] = ["Frodo Baggins", "Samwise Gamgee", "Aragorn", "Legolas", "Gimli"]
    TextField_Suggestions(label: "inline", text: $text, prompt: nil, style:.inline, suggestions:suggestions)
        .textFieldStyle(.roundedBorder)
        .padding(20)
    
    
    TextField_Suggestions(label: "menu", text: $text, prompt: nil, style:.menu, suggestions:suggestions)
        .textFieldStyle(.roundedBorder)
        .padding(20)
    
    TextField_Suggestions(label: "both", text: $text, prompt: nil, style:.both, suggestions:suggestions)
        .textFieldStyle(.roundedBorder)
        .padding(20)
    
    TextField_Suggestions(label: "Nil", text: $text, prompt: nil, style:nil, suggestions:suggestions)
        .textFieldStyle(.roundedBorder)
        .padding(20)
}
