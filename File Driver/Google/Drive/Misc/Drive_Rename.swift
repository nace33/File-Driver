//
//  Drive_Rename.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/30/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct Drive_Rename: View {
    init(title:String = "Rename Files", sectionTitle:String = "", files: [GTLRDrive_File], delimiter: String = "#", saveOnServer:Bool, isSheet:Bool = false, renamed:@escaping(([GTLRDrive_File]) -> Void)) {
        _files = State(initialValue: File.convert(files))
        self.delimiter = delimiter
        self.renamed = renamed
        self.title = title
        self.sectionTitle = sectionTitle
        self.saveOnServer = saveOnServer
        _prefix = State(initialValue: "\(delimiter) ")
        _digits = State(initialValue: files.count.digits)
        self.isSheet = isSheet
    }
    var title : String
    var sectionTitle : String
    let saveOnServer : Bool
    var renamed : (([GTLRDrive_File]) -> Void)
    var delimiter : String
    let isSheet: Bool
    @State private var files : [File]
    
    @State private var prefix   : String
    @State private var filename : String = ""
    @State private var suffix   : String = ""
    @State private var date     : Date = Date()
    @State private var digits   : Int
    @State private var renameIteratorStyle = RenameIterator.number
    @State private var changeOrder : Bool = false
    @State private var isRenaming = false
    @State private var renameError : Error?
    @State private var statusString = ""
    @State private var failureMessage :String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStackLoader(title:title, isLoading: $isRenaming, status: $statusString, error: $renameError) {
            Form {
                Section {
                    renameFieldsSection
                    renameListSection
                } header: {
                    if !sectionTitle.isEmpty {
                        HStack {
                            Text(sectionTitle)
                                .font(.title2)
                        }.frame(minHeight: 32)
                    }
                }
            }.formStyle(.grouped)
        }
            .task {
                updateFilenames()
            }
            .toolbar {
                if isSheet {
                    ToolbarItem(placement: .cancellationAction) {  Button(isRenaming ? "Close" : "Cancel") { dismiss() }  }
                    ToolbarItem(placement: .primaryAction) { renameButton   }
                }
            }
    }
    @ViewBuilder var renameFieldsSection : some View {
        Section {
            Picker("Style", selection:$renameIteratorStyle) {
                ForEach(RenameIterator.allCases, id:\.self) { Text($0.rawValue.camelCaseToWords())}
            }
                .onChange(of: renameIteratorStyle) { _, _ in
                    updateFilenames()
                }
            if renameIteratorStyle == .date {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .onChange(of: date) { _, _ in
                        updateFilenames()
                    }
            }
            if renameIteratorStyle == .numberPadded {
                TextField("Digits", value: $digits, format:.number)
                    .onChange(of: digits) { _, _ in
                        updateFilenames()
                    }
            }
            TextField("Prefix", text: $prefix, prompt: Text("enter prefix here"))
                .onChange(of: prefix) { _, _ in
                    updateFilenames()
                }
            TextField("Filename", text: $filename, prompt: Text("leave blank to use existing filename"))
                .onChange(of: filename) { _, _ in
                    updateFilenames()
                }
            TextField("Suffix", text: $suffix, prompt: Text("enter suffix here"))
                .onChange(of: suffix) { _, _ in
                    updateFilenames()
                }
            if !iteratorFound {
                LabeledContent(" ") { Text("You must include a '#' in prefix or suffix").font(.caption).foregroundStyle(.orange)}
            }
        } footer: {
            if !isSheet ||  failureMessage != nil {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing) {
                        if !isSheet {
                            renameButton
                        }
                        if let failureMessage {
                            Text(failureMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder var renameListSection : some View {
        Section {
            ForEach(files) { renamedForm in
                Text(renamedForm.newFilename)
            }
                .onMove(perform: move)
        } header: {
            HStack {
                Text("Files will be renamed:")
                Spacer()
                Button("Change Order") { changeOrder.toggle() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                    .sheet(isPresented: $changeOrder) {
                        reOrderList
                    }
            }
        }
    }
    @ViewBuilder var reOrderList : some View {
        List {
            Section {
                ForEach(files) { renameFile in
                    Text(renameFile.originalFile.title)
                        .contextMenu {
                            if let index = files.firstIndex(of: renameFile) {
                                if index != 0 {
                                    Button("Send to top") { move(from: IndexSet(integer: index), to: 0)}
                                }
                                if index != files.count - 1  {
                                    Button("Send to bottom") { move(from: IndexSet(integer: index), to: files.count)}
                                }
                            }
                        }
                }
                .onMove(perform: move)
            } header: {
                HStack {
                    Text("Reorder Files").font(.title3)
                    Spacer()
                    Button("Done") { changeOrder.toggle()}
                        .buttonStyle(.borderedProminent)
                }.padding(.vertical, 8)
            }
        }
            .alternatingRowBackgrounds()
            .frame(minHeight: 400)
    }
    @ViewBuilder var renameButton : some View {
        Button("Rename") { Task { await renameFiles()}}
            .buttonStyle(.borderedProminent)
            .disabled(!canRename)
            .disabled(isRenaming)
    }
    
    
    private var iteratorFound : Bool {
        prefix.contains("#") || suffix.contains("#")
    }
    private var canRename : Bool {
        guard iteratorFound else { return false }
        guard files.filter({ $0.newFilename.isEmpty}).count == 0 else { return false }
        guard files.filter({ $0.originalFile.title == $0.newFilename }).count == 0 else { return false }
        return true
    }
    private func move(from source: IndexSet, to destination: Int) {
        files.move(fromOffsets: source, toOffset: destination)
        var order = 1
        
        for (index, _) in files.enumerated() {
            files[index].order = order
            order += 1
        }
        updateFilenames()
    }
    private func updateFilenames() {
        func iterator(_ index:Int) -> String {
            switch renameIteratorStyle {
            case .letter:
                (index - 1).letter
            case .number:
                "\(index)"
            case .numberPadded:
                String(format: "%0\(digits)d", index)
            case .date:
                date.yyyymmdd
            }
        }
        func prefixString(_ counter:Int) -> String {
            guard let index = prefix.firstIndex(of: "#") else { return prefix}
            let pre = prefix.prefix(upTo: index)
            let val = iterator(counter)
            let post = prefix.suffix(from: index).dropFirst()
            return String(pre + val + post)
        }
        func suffixString(_ counter:Int) -> String {
            guard let index = suffix.firstIndex(of: "#") else { return suffix}
            let pre = suffix.prefix(upTo: index)
            let val = iterator(counter)
            let post = suffix.suffix(from: index).dropFirst()
            return String(pre + val + post)
        }
        for (index, _) in files.enumerated() {
            let order = files[index].order
            let existingName = files[index].originalFile.title
            if var name = files[index].originalFile.name,
                let pathExtension = files[index].originalFile.fileExtension,
                let range = name.range(of: "."+pathExtension) {
                name.removeSubrange(range)
                files[index].newFilename =  prefixString(order) + (filename.isEmpty ? name : filename) + suffixString(order) + "." + pathExtension
            } else {
                files[index].newFilename =  prefixString(order) + (filename.isEmpty ? existingName : filename) + suffixString(order)
            }
        }
    }
    private func renameFiles() async {
        do {
            isRenaming = true
            if failureMessage != nil { failureMessage = nil }

            self.statusString = "Renaming files ..."
         
            let tuples = files.compactMap { $0.tuple }
           
            if saveOnServer {
                let result = try await Drive.shared.update(tuples: tuples)
                
                var renamedFiles : [GTLRDrive_File] = []
                if let successes = result.successes {
                    renamedFiles = successes.compactMap { $0.value as? GTLRDrive_File }
                }
                
                DispatchQueue.main.async {
                    self.renamed(renamedFiles)
                }
                
                if let error = result.failures?.first?.value.foundationError {
                    failureMessage = error.localizedDescription
                }
            } else {
                DispatchQueue.main.async {
                    self.renamed(renamedFilesWithIds)
                }
            }

            self.statusString = "Done!"
            isRenaming = false
           
   
            self.updateFilenames()
            if isSheet { dismiss() }
        } catch {
            isRenaming = false
            self.renameError = error
        }
    }
    
    var renamedFilesWithIds : [GTLRDrive_File] {
        files.compactMap { file in
            let newFile = GTLRDrive_File()
            if let fileExtension = file.originalFile.fileExtension {
                newFile.name = file.newFilename.replacingOccurrences(of:".\(fileExtension)", with: "")
            } else {
                newFile.name = file.newFilename
            }
            newFile.fileExtension = file.originalFile.fileExtension
            newFile.mimeType = file.originalFile.fileExtension
            newFile.parents = file.originalFile.parents
            newFile.identifier = file.id
            return newFile
        }
    }
}


fileprivate enum RenameIterator : String, CaseIterable {
    case letter, number, numberPadded, date
}

fileprivate struct File : Identifiable, Hashable {
    var id : String { originalFile.id }
    let originalFile : GTLRDrive_File
    var order : Int

    var newFilename : String = ""
    var tuple : (id:String, file:GTLRDrive_File) {
        let newFile = GTLRDrive_File()
        newFile.name = newFilename
        //newFile.identifier = id //will cause google error as 'id' property cannot be updated.
        return (id:id, file:newFile)
    }

    static func convert(_ files : [GTLRDrive_File]) -> [File] {
        var order = 1
        return files.compactMap { file in
            let file = File(originalFile: file, order: order)
            order += 1
            return file
        }
    }
}
