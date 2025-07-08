//
//  Filer_Form.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/2/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce


struct FileToCase_Form: View {
    @Environment(FileToCase_Delegate.self) var delegate
    
    @State private var newTaskString = ""
    @State private var isCreatingTask = false
    @State private var error : Error?
    @State private var showFileRenameSheet = false
    enum Field { case filenameField, taskField }
    @FocusState var focusField: Field?

    @State private var contactText  = ""
    @State private var tagText  = ""
    @AppStorage(BOF_Settings.Key.filingShowMultipleFilenames.rawValue)        var filenamesExpanded   : Bool = true

    var body: some View {
        Form {
            filenameFields
            
            contactsSection
            
            tagsSection

            Section {
                tasksField
                tasksList
            } header: { EmptyView() }
              footer: {  HStack {Spacer(); errorView } }
        }
            .formStyle(.grouped)
            .onAppear() {
                focusField = .filenameField
            }
    }
    
}


//MARK: - Actions
fileprivate extension FileToCase_Form {
    func createTask() async {
        self.error = nil
        guard newTaskString.count > 0 else { return }
        let taskString = newTaskString.trimmingCharacters(in: .whitespaces)
        do {
            newTaskString = ""
            isCreatingTask = true
            if delegate.selectedCase?.permissions.isEmpty ?? false {
                try await delegate.selectedCase?.loadPermissions()
            }
            
//            if Bool.random() {
//                throw NSError.quick("Just checking my pants")
//            }
            let newTask = Case.Task(id: UUID().uuidString, parentID: "", fileIDs: [], contactIDs: [], tagIDs: [], assigned:[], priority:.none, status:.notStarted, isFlagged: false, text: taskString)
            withAnimation {
                delegate.filingTasks.insert(newTask, at:0)
            }
            isCreatingTask = false
            focusField = .taskField
        } catch {
            newTaskString = taskString
            self.error = error
            isCreatingTask = false
            focusField = .taskField
        }
    }
    func delete(_ task:Case.Task) {
        if let index = delegate.filingTasks.firstIndex(of: task) {
            withAnimation {
             _ = delegate.filingTasks.remove(at: index)
            }
        }
    }
}


//MARK: - View Builders
fileprivate extension FileToCase_Form {
    @ViewBuilder var errorView     : some View {
        if let error {
            HStack {
                Spacer()
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
                    .onTapGesture {
                        self.error = nil
                    }
            }
        }
    }
    
    //Filename
    @ViewBuilder var filenameFields : some View {
        if delegate.filingNames.count == 1 {
            TextField(text: Bindable(delegate).filingNames[0].text, prompt:  Text("Enter filename here"), axis: .vertical) {
                Menu {
                    Button("Reset") { delegate.loadFilingNames()}
                } label: {
                    Text("Filename")
                }
                    .fixedSize()
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
            }
//                .focused($focusField, equals: .filenameField)
        } else {
            Section {
                if filenamesExpanded {
                    ForEach(Bindable(delegate).filingNames) { $filename in
                        if $filename.wrappedValue == delegate.filingNames.first {
                            TextField(text: $filename.text, prompt: Text("Enter filename here"), axis: .vertical) {
                                EmptyView()
                            }
                            //                            .focused($focusField, equals: .filenameField)
                        } else {
                            TextField(text: $filename.text, prompt: Text("Enter filename here"), axis: .vertical) {
                                EmptyView()
                            }
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("\(delegate.filingNames.count) files are selected.")
                    }
                }
            } header: {
                Menu {
                    Button("Rename") { showFileRenameSheet = true }
                    Divider()
                    Button("Reset") { delegate.loadFilingNames()}
                } label: {
                    Text("Files")
                }
                    .fixedSize()
                    .menuStyle(.borderlessButton)
      
            } footer: {
                HStack {
                    Spacer()
                    Text(filenamesExpanded ? "Hide Filenames" : "Show Filenames")
                        .font(.subheadline)
                        .hoverStyle(outsideColor: .secondary)
                        .onTapGesture {
                            filenamesExpanded.toggle()
                        }
                }
            }
            .sheet(isPresented: $showFileRenameSheet) {
                Drive_Rename(files: delegate.files, saveOnServer: false, isSheet: true) { renamedFiles in
                    for renamedFile in renamedFiles {
                        if let index = delegate.filingNames.firstIndex(where: {$0.id == renamedFile.id}) {
                            delegate.filingNames[index].text = renamedFile.titleWithoutExtension
                        }
                    }
                }
            }
        }
    }
    
    //Contacts
    @ViewBuilder var contactsSection : some View {
        let current  = delegate.filingContacts.compactMap({$0.name}).joined()
        let eligible = delegate.selectedCase?.contacts.filter({!current.ciContain($0.name)  }) ?? []
        Section {
            LabeledContent {
                TextField("Contacts", text:$contactText, prompt: Text("Add Contacts"))
                    .labelsHidden()
                    .textInputSuggestions {
                        if contactText.count > 0 {
                            let matches = delegate.selectedCase?.contacts.filter({$0.name.ciHasPrefix(contactText) && !current.ciContain($0.name)  }) ?? []
                            ForEach(matches) {  Text($0.name) .textInputCompletion($0.name) }
                        }
                    }
                    .onSubmit {
                        _ = delegate.addNewFilingContact(contactText)
                        contactText = ""
                    }
            } label: {
                Menu("Contacts") {
                    if eligible.count > 10 {
                        BOFSections(.menu, of: eligible , groupedBy: \.name, isAlphabetic: true) { letter in
                            Text(letter)
                        } row: { contact in
                            Button(contact.name) { delegate.addFilingContact(contact)  }
                        }
                    } else {
                        ForEach(eligible.sorted(by: {$0.name.ciCompare($1.name)})) { contact in
                            Button(contact.name) { delegate.addFilingContact(contact)  }
                        }
                    }
                }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(eligible.isEmpty ? .hidden : .visible)
                    .labelsHidden()
                    .fixedSize()
            }
            if delegate.filingContacts.count > 0 {
                Flex_Stack(data: delegate.filingContacts, alignment: .trailing) { contact in
                    let isExisting = delegate.contactIsInSpreadsheet(contact.id)
                    Text(contact.name)
                        .tokenStyle(color:isExisting ? .blue : .orange,  style:.strike) {
                            delegate.removeFilingContact(contact.id)
                        }
                }
            }
        }
    }
    
    //Tags
    @ViewBuilder var tagsSection     : some View {
        Section {
            let current  = delegate.filingTags.compactMap({$0.name}).joined()
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
                        _ = delegate.addNewTag(tagText)
                        tagText = ""
                    }
            } label: {
                Menu("Tags") {
                    if eligible.count > 10 {
                        BOFSections(.menu, of: eligible , groupedBy: \.name, isAlphabetic: true) { letter in
                            Text(letter)
                        } row: { tag in
                            Button(tag.name) { delegate.addTag(tag)  }
                        }
                    } else {
                        ForEach(eligible.sorted(by: {$0.name.ciCompare($1.name)})) { tag in
                            Button(tag.name) { delegate.addTag(tag)  }
                        }
                    }
                }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(eligible.isEmpty ? .hidden : .visible)
                    .labelsHidden()
                    .fixedSize()
            }
            if delegate.filingTags.count > 0 {
                Flex_Stack(data: delegate.filingTags, alignment: .trailing) { tag in
                    let isExisting = delegate.tagIsInSpreadsheet(tag.id)
                    Text(tag.name)
                        .tokenStyle(color:isExisting ? .green : .orange,  style:.strike) {
                            delegate.removeTag(tag.id)
                        }
                }
            }
        }
    }
    
    //Tasks
    @ViewBuilder var tasksField    : some View {
        TextField("Tasks", text: $newTaskString, prompt: Text(isCreatingTask ? "Creating..." :  "New Task"))
            .onSubmit { Task { await  createTask() }  }
            .disabled(isCreatingTask)
            .focused($focusField, equals: .taskField)
    }
    @ViewBuilder var tasksList    : some View {
        ForEach(Bindable(delegate).filingTasks) { task in
            HStack(alignment:.top) {
                FileToCase_TaskRow(task:task, permissions: delegate.selectedCase?.permissions ?? [])
                Button {delete(task.wrappedValue) } label: {  Image(systemName: "trash") }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                    .frame(minHeight:22)
            }
        }
    }
}
