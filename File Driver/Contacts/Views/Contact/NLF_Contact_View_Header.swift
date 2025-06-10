//
//  NLF_Contact_Header.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/4/25.
//

import SwiftUI

struct NLF_Contact_View_Header: View {
    @Binding var contact : NLF_Contact
    @Binding var isEditing : Bool
    @Environment(NLF_ContactsController.self) var controller
    @State private var isUpdating = false
    @State private var showNewSheet = false
    
    var body: some View {
        GridRow {
            NLF_Contact_ImageField(contact: $contact, isEditing: $isEditing)
                .frame( alignment: .trailing)
                .padding(.leading)
                
            if isEditing {
                editNameViews
                    .padding(.trailing)
            } else {
                nameViews
                    .padding(.trailing)
                    .sheet(isPresented: $showNewSheet) { NLF_Contact_SheetRow_Add($contact) }
            }
        }
            .frame(minHeight: 75)
    }
    
    var groups : [String] {
        if contact.label.groupName.isEmpty {
            controller.groups.filter { !$0.isEmpty }
        } else {
            controller.groups.filter { !$0.isEmpty && $0.ciHasPrefix(contact.label.groupName) && $0.lowercased() != contact.label.groupName.lowercased() }
        }
    }
}

//MARK: - Actions
fileprivate extension NLF_Contact_View_Header {
    func addContactSheetRow(for category:String) async {
        do {
            isUpdating = true
            let suggestion : String
            if let cat = NLF_Contact.SheetRow.Category(rawValue: category.wordsToCamelCase()), let sug = cat.labels.first, !sug.isEmpty {
                suggestion = sug
            } else {
                suggestion = "New Label"
            }
            
            let newRow = NLF_Contact.SheetRow.new(sheet:NLF_Contact.Sheet.contactInfo, status:.editing, category: category, label: suggestion, value: "Change Me")

            try await controller.sheetRow(.add, row: newRow, from: contact)

            isUpdating = false
        } catch {
            isUpdating = false
//            self.error = error
        }
    }
    func updateDriveLabel() async {
        do {
            isUpdating = true
            _ = try await controller.update(file: contact.file, label: contact.labelModification)
            isUpdating = false
        } catch {
            isUpdating = false
        }
    }
}


//MARK: - View Builders
fileprivate extension NLF_Contact_View_Header {
    @ViewBuilder var nameViews     : some View {
        HStack {
            VStack(alignment:.leading) {
                HStack {
                    Text(contact.name)
                        .font(.title2)
                    
                    actionMenuView
                }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 2)
                    
                HStack {
                    Text(contact.label.client.title)
                        .tokenStyle(color:.gray, style:.stroke)
                        .font(.system(size: 11))

                    Text(contact.label.groupName.isEmpty ? "No Group" : contact.label.groupName)
                        .font(.system(size: 11))
                        .tokenStyle(color:.gray, style:.stroke)
                }
                .fixedSize()
                .foregroundStyle(.secondary)


            }
        }
    }
    @ViewBuilder var editNameViews : some View {
        HStack {
            VStack(alignment:.leading) {
                HStack {
                    TextField("First Name", text: $contact.label.firstName, prompt: Text("First Name"))
                        .fixedSize()
                    TextField("Last Name", text: $contact.label.lastName, prompt: Text("Last Name"))
                        .fixedSize()
                

                    Button("Done") { isEditing.toggle() }
                        .font(.caption)
                        .buttonStyle(.link)
                    
                }
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Picker("Client", selection: $contact.label.client) { ForEach(NLF_Contact.DriveLabel.ClientStatus.allCases, id:\.self) { client in Text(client.title)} }
                        .onChange(of: contact.label.client) { _, _ in
                            Task { await updateDriveLabel() }
                        }
                    TextField("Group", text: $contact.label.groupName, prompt: Text("Enter group name"))
                        .textInputSuggestions(groups, id:\.self, content: { group in
                            Text(group)
                                .textInputCompletion(group)
                        })
                }
                .font(.system(size: 11))
                .labelsHidden()
                .fixedSize()
            }
                .onSubmit {  Task { await updateDriveLabel() }   }
                .disabled(isUpdating)
                .textFieldStyle(.roundedBorder)
        }
    }
    @ViewBuilder var actionMenuView: some View {
        Menu {
            ForEach(NLF_Contact.SheetRow.Category.allCases.compactMap({$0.title}) ,id:\.self) { cat in
                Button(cat) {Task { await addContactSheetRow(for:cat)} }
            }
            Divider()
            Button("Custom") { showNewSheet.toggle() }
        } label: {
            Image(systemName: "plus")
                .font(.caption)
                .tint(.blue)
        }
        .fixedSize()
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
    @ViewBuilder var actionMenuView2: some View {
        Menu {
            Button("Edit") { isEditing.toggle() }
                .modifierKeyAlternate(.command) {
                    Button("Edit Google Sheet") { File_DriverApp.createWebViewTab(url: contact.file.editURL, title: contact.name) }
                }
            Divider()
            Menu {
                ForEach(NLF_Contact.SheetRow.Category.allCases.compactMap({$0.title}) ,id:\.self) { cat in
                    Button(cat) {Task { await addContactSheetRow(for:cat)} }
                }
                Divider()
                Button("Custom") { showNewSheet.toggle() }
            } label: {
                Label("Add Info", systemImage: "person")
            } primaryAction: {
                showNewSheet.toggle()
            }

        } label: {
            Image(systemName: "plus")
                .font(.caption)
                .tint(.blue)
        }
            .fixedSize()
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)

    }
    

 
}
