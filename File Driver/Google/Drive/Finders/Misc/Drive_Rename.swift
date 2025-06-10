//
//  Drive_Rename.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/30/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct Drive_Rename: View {
    init(files: [GTLRDrive_File], delimiter: String = "#", title:String = "Rename Files", renamed:@escaping((GTLRDrive_File, Bool) -> Void)) {
        
        _files = State(initialValue: File.convert(files))
        self.delimiter = delimiter
        self.renamed = renamed
        self.title = title
        _prefix = State(initialValue: "\(delimiter) ")
        _digits = State(initialValue: files.count.digits)
    }
    var title : String
    var renamed : ((GTLRDrive_File, Bool) -> Void)
    var delimiter : String
    
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
    
    var body: some View {
        VStackLoader(title:title, isLoading: $isRenaming, status: $statusString, error: $renameError) {
            Form {
                renameFieldsSection
                renameListSection
            }.formStyle(.grouped)
        }.task {
            updateFilenames()
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
            HStack {
                Spacer()
                Button("Rename") { Task { await renameFiles()}}
                    .buttonStyle(.borderedProminent)
                    .disabled(!canRename)
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
            var renamedFiles : [GTLRDrive_File] = []
            for file in files {
                self.statusString = "Renaming:\n\(file.originalFile.title)\nto\n\(file.newFilename)"
                let renamedFile = try await Google_Drive.shared.rename(id: file.originalFile.id, newName: file.newFilename)
                renamedFiles.append(renamedFile)
                DispatchQueue.main.async {
                    self.renamed(renamedFile, file == files.last)
                }
            }
            self.statusString = "Done!"
            isRenaming = false
           
            self.files = File.convert(renamedFiles)
            self.updateFilenames()
        } catch {
            isRenaming = false
            self.renameError = error
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
    
    static func convert(_ files : [GTLRDrive_File]) -> [File] {
        var order = 1
        return files.compactMap { file in
            let file = File(originalFile: file, order: order)
            order += 1
            return file
        }
    }
}
