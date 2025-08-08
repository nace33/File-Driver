//
//  Renamer.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/7/25.
//

import SwiftUI
import BOF_SecretSauce

struct Renamer<T>: View {
    let title : String
    let items : [T]
    let key   : KeyPath<T, String>
    let canReorder : Bool
    let save  : ( [RenameItem<T>] ) -> Void
    init(title: String, items: [T], key: KeyPath<T, String>, canReorder:Bool, save: @escaping ([RenameItem<T>]) -> Void) {
        self.title = title
        self.items = items
        self.canReorder = canReorder
        self.key = key
        self.save = save
        
        var renameItems = [RenameItem<T>]()
        for (index, item) in items.enumerated() {
            renameItems.append(RenameItem(item: item, key: key, position: index))
        }
        _renameItems = State(initialValue:renameItems)
    }
    
    @State private var renameItems : [RenameItem<T>]
    
    @State private var prefix     : String   = ""
    @State private var middle     : String   = ""
    @State private var suffix     : String   = ""
    @State private var remove     : String   = ""
    @State private var date       : Date     = Date()
    @State private var numberStartAt   : Int      = 0
    @State private var letterStartAt   : Int      = 0
    @State private var digits    : Int      = 1
    @State private var changeOrder : Bool = false
    @State private var showOptions = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section {
                TextField("Prefix", text: $prefix, prompt:Text("type '@' for letter, '#' for number, '$' for date"))
                TextField("Middle", text: $middle, prompt:Text("Keep blank to use existing"))
                TextField("Suffix", text: $suffix, prompt:Text("enter suffix here"))
                TextField("Remove", text: $remove, prompt:Text("remove text in common"))
            } header: {
                HStack {
                    Text(title)
                    Spacer()
                    Button("Options") { showOptions = true  }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue )
                        .popover(isPresented: $showOptions, arrowEdge: .bottom) { optionsView  }

                }
            }
 
            List {
                Section("Preview") {
                    if canReorder {
                        ForEach(renameItems) { item in
                            Text(convert(item.originalString, position: item.position))
                        }
                        .onMove(perform: moveItems)
                    } else {
                        ForEach(renameItems) { item in
                            Text(convert(item.originalString, position: item.position))
                        }
                    }
                }
            }.frame(minHeight: 150)
        }
            .formStyle(.grouped)
            .presentationSizing(.fitted) // Allows resizing, sizes to content initially
            .task { reset() }
            .toolbar { toolbarView }
    }
  
    var canSave : Bool { !prefix.isEmpty || !middle.isEmpty || !suffix.isEmpty || !remove.isEmpty}
    var hasLetterToken : Bool { (prefix + middle + suffix).contains("@") }
    var hasNumberToken : Bool { (prefix + middle + suffix).contains("#")}
    var hasDateToken   : Bool { (prefix + middle + suffix).contains("$") }
    func expand(_ string:String, position:Int) -> String {
        var str = ""
        for c in string {
            if c == "@" {
                str += (position + letterStartAt).letter
            } else if c == "#" {
                str +=  String(format: "%0\(digits)d", position + numberStartAt)
            } else if c == "$" {
                str += "\(date.yyyymmdd)"
            } else {
                str += String(c)
            }
        }
        return str
    }
    func prefix(_ position:Int) -> String {
        expand(prefix, position: position)
    }
    func middle(string:String, position:Int) -> String {
        guard !middle.isEmpty else { return string }
        return expand(middle, position: position)
    }
    func suffix(_ position:Int) -> String {
        expand(suffix, position: position)
    }
    func convert(_ string:String, position:Int) -> String {
        let str = string.replacingOccurrences(of:remove, with: "").trimmingCharacters(in: .whitespaces)
        return prefix(position) + middle(string:str, position:position) + suffix(position)
    }
    func reset() {
        prefix   = ""
        middle   = ""
        suffix   = ""
        var renameItems = [RenameItem<T>]()
        for (index, item) in items.enumerated() {
            renameItems.append(RenameItem(item: item, key: key, position: index))
        }
        self.renameItems = renameItems
    }
    func saveItems() {
        for item in $renameItems {
            item.wrappedValue.string = convert(item.wrappedValue.originalString, position: item.wrappedValue.position)
        }
        save($renameItems.wrappedValue)
        dismiss()
    }
    func moveItems(from source: IndexSet, to destination: Int) {
        renameItems.move(fromOffsets: source, toOffset: destination)
        for (index, item) in $renameItems.enumerated() {
            item.wrappedValue.position = index
        }
    }
    @ToolbarContentBuilder var toolbarView : some ToolbarContent {
        ToolbarItem(placement: .destructiveAction) {
            Button("Reset") { reset() }
        }
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .primaryAction) {
            Button("Save") { saveItems() }
                .disabled(!canSave)
        }
    }
    @ViewBuilder var optionsView : some View  {
        Form {
            Section("Numbers") {
                TextField("Start At", value: $numberStartAt, format:.number)
                TextField("Padding", value: $digits, format:.number)
            }
            Section("Letters") {
                TextField("Start At", value: $letterStartAt, format:.number)
            }
            
            Section("Dates") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
        }
        .frame(width:220)
        .formStyle(.grouped)
    }
}
#Preview {
    Renamer(title:"New Filenames", items: ["Gandolf", "Frodo Baggins", "Bilbo Baggins", "Samwise Gamgee"], key:\.self, canReorder: true) { saveItems in
        for item in saveItems {
            print("Item Original: \(item.item[keyPath: item.key])\tNew: \(item.string)")
        }
    }
}

struct RenameItem<T> : Identifiable {
    let id        : String = UUID().uuidString
    let item      : T
    let key       : KeyPath<T, String>
    var string    : String = ""
    var originalString : String { item[keyPath: key]}
    var position  : Int
    init(item: T, key: KeyPath<T, String>,  position: Int) {
        self.item     = item
        self.key      = key
        self.string   = item[keyPath: key]
        self.position = position
    }
}


