//
//  Settings_Filing.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI
import SwiftData
import BOF_SecretSauce

struct Settings_Filing: View {
    typealias AutoRenamer = AutoFile_Rename
    @AppStorage(BOF_Settings.Key.filingDrive.rawValue)                     var driveID            : String = ""
    @AppStorage(BOF_Settings.Key.filingAutoRename.rawValue)                var autoRenameFiles    : Bool = true
    @AppStorage(BOF_Settings.Key.filingAutoRenameComponents.rawValue     ) var filenameComponents : [AutoRenamer]  = AutoRenamer.defaultFilename
    @AppStorage(BOF_Settings.Key.filingAutoRenameEmailComponents.rawValue) var emailComponents    : [AutoRenamer]  = AutoRenamer.defaultEmail
//    @AppStorage(BOF_Settings.Key.renameItemsInListView.rawValue)           var renameListItems    : Bool = true
    
    @AppStorage(BOF_Settings.Key.filingSuggestionLimit.rawValue)           var suggestionLimit      : Int = 5
    @AppStorage(BOF_Settings.Key.filingSuggestionPartialTagMatch.rawValue)        var allowTagPartialMatch   : Bool = false

    
    
    @Environment(\.modelContext) private var modelContext
    @Query(filter:#Predicate<WordSuggestion>{ $0.isBlocked == true },sort:\WordSuggestion.text) private var blockedWords: [WordSuggestion]
    @State private var showNewBlockWordSheet: Bool = false
    
    var body: some View {
        Form {
            TextField("DriveID", text: $driveID)
            
            Section("Importing") {
                Toggle("Automatically Rename Files", isOn:$autoRenameFiles)
                LabeledContent("Name Format")  { components($filenameComponents, showEmail: false)  }
                    .disabled(!autoRenameFiles)
                LabeledContent("Email Format") { components($emailComponents   , showEmail: true )  }
                    .disabled(!autoRenameFiles)
            }
            
            Section {
                TextField("Suggestions Shown", value: $suggestionLimit, format: .number)
                Toggle("Allow Tag Partial Match", isOn: $allowTagPartialMatch)

                LabeledContent("Block Words") {
                    if blockedWords.isEmpty {
                        Text("No words are blocked.").foregroundStyle(.secondary)
                    } else {
                        VStack(alignment:.trailing) {
                            ForEach(blockedWords, id:\.self) {b in
                                Text(b.text)
                                    .textSelection(.disabled)
                                    .contextMenu {
                                        Button("Remove") { modelContext.delete(b)}
                                    }
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Suggestions")
                    Button {showNewBlockWordSheet.toggle() } label: { Image(systemName:"plus")}
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                }
            }
          
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showNewBlockWordSheet) {
            TextSheet(title: "Block Word", prompt: "Add") { text in
                try? FilingController.shared.suggestions.block(text)
                return nil
            }
        }
    }
}

//MARK: View Builders
extension Settings_Filing {
    @ViewBuilder func components(_ components:Binding<[AutoRenamer]>, showEmail:Bool) -> some View {
        VStack(alignment:.trailing) {
            HStack {
                ForEach(Array(components.enumerated()), id: \.offset) { index, element in
                    Button(element.wrappedValue.title) {
                        components.wrappedValue.remove(at: index)
                    }
                    .hoverStyle(highlight:.strikethrough, color: .red, outsideColor: .blue)
                    .buttonStyle(.plain)
                    .disabled(components.count == 1)
                }
                menu(components, showEmail: showEmail)
            }
            Text(components.wrappedValue.map(\.sampleString).joined()).padding(.top, 1)
        }
    }
    @ViewBuilder func menu(_ components:Binding<[AutoRenamer]>, showEmail:Bool) -> some View {
        Menu("Add") {
            Menu("Filename") {
                ForEach(AutoRenamer.allFilename, id:\.self) { component in
                    Button(component.title) { components.wrappedValue.append(component)}
                }
            }
            if showEmail {
                Menu("Email") {
                    ForEach(AutoRenamer.allEmail, id:\.self) { component in
                        Button(component.title) { components.wrappedValue.append(component)}
                    }
                }
            }
            Menu("Punctuation") {
                ForEach(AutoRenamer.allPuntuation, id:\.self) { component in
                    Button(component.title) { components.wrappedValue.append(component)}
                }
            }
            Divider()
            if showEmail {
                Button("Date [Space] Host [Space] ( Subject )") {
                    components.wrappedValue = [.emailDate, .space, .emailHost, .space, .openParenthesis, .emailSubject ,.closeParenthesis ]
                }
            } else {
                Button("DateAdded [Space] Filename") {
                    components.wrappedValue = [.dateAdded, .space, .filename ]
                }
            }
        }.fixedSize()
    }
}


#Preview {
    Settings_Filing()
}
