//
//  Settings_Filing.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI
import SwiftData
import BOF_SecretSauce

struct Tester : View {
    let blocked :FilerBlockText
    var body: some View {
        Picker("Style", selection:Bindable(blocked).category) {
            Text("Exact").tag(FilerBlockText.Category.exact)
            Text("Contains").tag(FilerBlockText.Category.contains)
        }.fixedSize()
    }
}
struct Settings_Filing: View {
    typealias AutoRenamer = AutoFile_Rename
    @AppStorage(BOF_Settings.Key.filingDrive.rawValue)                     var driveID            : String = ""
    @AppStorage(BOF_Settings.Key.filingAutoRename.rawValue)                var autoRenameFiles    : Bool = true
    @AppStorage(BOF_Settings.Key.filingAutoRenameComponents.rawValue     ) var filenameComponents : [AutoRenamer]  = AutoRenamer.defaultFilename
    @AppStorage(BOF_Settings.Key.filingAutoRenameEmailComponents.rawValue) var emailComponents    : [AutoRenamer]  = AutoRenamer.defaultEmail
    
    @AppStorage(BOF_Settings.Key.filingSuggestionLimit.rawValue)           var suggestionLimit      : Int = 5

    @AppStorage(BOF_Settings.Key.filingAllowSuggestions.rawValue)          var allowSuggestions    : Bool = true
    @AppStorage(BOF_Settings.Key.filingFormContactMatch.rawValue)          var allowContactMatch   : Bool = true
    @AppStorage(BOF_Settings.Key.filingFormTagMatch.rawValue)              var allowTagMatch       : Bool = true

    @Environment(\.modelContext) private var modelContext
    @Query(sort:\FilerBlockText.text) private var blockedRenameWords: [FilerBlockText]
    
    
    @State private var showDriveSelector: Bool = false
    @State private var showNewBlockedAutoNameSheet: Bool = false
    @Environment(\.openWindow) var openWindow

    var body: some View {
        Form {
            Section("Default location to save documents to be filed later") {
                TextField("DriveID", text: $driveID)
                LabeledContent("") {
                    Spacer()
                    Button("Select") { showDriveSelector = true }
                        .sheet(isPresented: $showDriveSelector) {
                            DriveSelector("Select Filing Drive", showCancelButton: true, canLoadFolders: false, fileID: $driveID)
                                .frame(minHeight: 400)
                        }
                }
            }
            blockTextSection
            filingFormSection
            importSection
        }
            .formStyle(.grouped)
            .sheet(isPresented: $showNewBlockedAutoNameSheet) {
                TextSheet(title: "Block Text", prompt: "Add") { text in
                    let alreadyBlocked = blockedRenameWords.compactMap({$0.text.lowercased()})
                    if !alreadyBlocked.contains(text.lowercased() ){
                        let newBlocked = FilerBlockText(text: text, category: .exact)
                        modelContext.insert(newBlocked)
                    }
                    return nil
                }
            }
    }
    @ViewBuilder var blockTextSection : some View {
        Section {
            VStack(alignment:.trailing) {
                ForEach(blockedRenameWords, id:\.self) { blocked in
                    LabeledContent{
                        Picker("Style", selection:Bindable(blocked).category) {
                            Text("Exact").tag(FilerBlockText.Category.exact)
                            Text("Contains").tag(FilerBlockText.Category.contains)
                        }.fixedSize()
                            .labelsHidden()
                    } label: {
                        Text(blocked.text)
                    }
                    .contextMenu {
                        Button("Delete") {
                            modelContext.delete(blocked)
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text("Block Text from filenames and suggestions")
                Button {showNewBlockedAutoNameSheet.toggle() } label: { Image(systemName:"plus")}
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                Spacer()
                if blockedRenameWords.count > 0 {
                    Text("Style").foregroundStyle(.secondary)
                }
            }
        }
    }
    @ViewBuilder var importSection : some View {
        Section("File Imports") {
            Toggle("Automatically Rename Files", isOn:$autoRenameFiles)
            LabeledContent("Name Format")  { components($filenameComponents, showEmail: false)  }
                .disabled(!autoRenameFiles)
            LabeledContent("Email Format") { components($emailComponents   , showEmail: true )  }
                .disabled(!autoRenameFiles)
    
        }
    }
    @ViewBuilder var filingFormSection: some View {
        Section("Filing Form") {
            LabeledContent("Case Suggestions") {
                VStack(alignment:.trailing) {
                    Toggle("Case Suggestions", isOn: $allowSuggestions)
                        .labelsHidden()
                        .toggleStyle(.switch)
                    HStack {
                        Text("Show:")
                            .foregroundStyle(.secondary)
                        TextField("Show:", value: $suggestionLimit, format: .number)
                            .fixedSize()
                            .disabled(!allowSuggestions)
                            .labelsHidden()

                    }
                    
                    Button("Open Database") {
                        openWindow(id: "SwiftData", value:BOF_SwiftDataView.ModelType.suggestions)
                    }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                }
            }
         

            
            Toggle("Add Contacts found in filing documents", isOn: $allowContactMatch)
            Toggle("Add Tags found in filing documents", isOn: $allowTagMatch)
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
