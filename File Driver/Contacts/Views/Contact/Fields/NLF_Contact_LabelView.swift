//
//  NLF.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//
import SwiftUI

struct NLF_Contact_LabelView : View {
    let prompt : String
    let fields : [Field]
    @Binding var contact : NLF_Contact
    var update : (NLF_Contact.Label) async -> Bool
    @State private var editLabel : NLF_Contact.Label
    
    
    enum Field : String, CaseIterable {
        case name, group, status, client, update, icon, timesUsed
        static var newFields : [Field]  {  [.name, .client]  }
        static var editFields : [Field] {  [.icon, .name, .client, .status, .group]  }
    }
    
    init(_ contact: Binding<NLF_Contact>, prompt:String, fields:[Field], update:@escaping(NLF_Contact.Label) async -> Bool) {
        _contact = contact
        _editLabel = State(initialValue: contact.wrappedValue.label)
        self.update = update
        self.prompt = prompt
        self.fields = fields
    }
    
    var needsToUpdate : Bool {
        guard editLabel.firstName.isEmpty == false else { return false }
        //if new fields, always allow updating unless firstName is empty
        if Set(fields).subtracting(Set(Field.newFields)).count == 0 {
            return true
        }
        return contact.label != editLabel
    }
    
    @ViewBuilder func view(for field:Field) -> some View {
        switch field {
        case .name:
            NLF_Contact_NameField($editLabel)
        case .group:
            TextField("Group", text: $editLabel.groupName)
        case .status:
            Picker("Status", selection: $editLabel.status) { ForEach(NLF_Contact.DriveLabel.Status.allCases, id:\.self) { Text($0.title)}}
        case .client:
            Picker("Client Status", selection: $editLabel.client) { ForEach(NLF_Contact.DriveLabel.ClientStatus.allCases, id:\.self) { Text($0.title)}}
        case .update:
            TextField("Update", text: $editLabel.updateID)
        case .icon:
            NLF_Contact_ImageField(contact: $contact, isEditing: .constant(true))
        case .timesUsed:
            TextField("Times Used", value: $editLabel.timesUsed, format: .number)

        }
    }
    
    var body: some View {
        Form {
            ForEach(fields, id:\.self) { view(for: $0)}
        }
            .formStyle(.grouped)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(prompt) { Task { await callUpdate()} }
                        .disabled(!needsToUpdate)
                }
            }
    }

    func callUpdate() async {
        if await update(editLabel) {
            contact.label = editLabel
        }
    }
}

