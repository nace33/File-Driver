//
//  NLF_Contact_View_Info_SheetData.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/4/25.
//

import SwiftUI
import BOF_SecretSauce

struct NLF_Contact_Info_SheetRow: View {
    @Binding var contact : NLF_Contact
    @Binding var isEditing : Bool
   var info : NLF_Contact.SheetRow
    
    init(contact: Binding<NLF_Contact>, isEditing: Binding<Bool>, info: NLF_Contact.SheetRow) {
        _contact    = contact
        print("INIt")
        _isEditing  = isEditing
        self.info   = info
        _editInfo   = State(initialValue: info)
    }
    @State private var showEditView = false
    @State private var showDeleteView = false
    @State private var editInfo : NLF_Contact.SheetRow
    @Environment(NLF_ContactsController.self) var controller

    
    var body: some View {
        GridRow(alignment:.center) {
            switch info.status {
            case .idle:
                normalView(row: info)
            case .editing, .updating:
                editingView()
//            case .updating:
//                normalView(row: editInfo).foregroundStyle(.orange)
            case .deleting:
                normalView(row: info).foregroundStyle(.red)
            }
        }
            .contextMenu {  menu()  }
            .onTapGesture(count: 2) {  if info.status == .idle  { updateStatus(.editing) }  }
            .sheet(isPresented: $showEditView)   { NLF_Contact_SheetRow_Update(info, from: $contact) }
            .sheet(isPresented: $showDeleteView) { NLF_Contact_SheetRow_Delete(info, from:$contact)}
            .task(id:info.id) { editInfo = info }
    }
}

//MARK: -Actions
fileprivate extension NLF_Contact_Info_SheetRow {
    var canUpdate : Bool {
        guard info.label.isEmpty == false else { return false }
        guard info.value.isEmpty == false else { return false }
        guard info != editInfo            else { return false }
        return true
    }
    func updateContactSheetRow(editAfterUpdate:Bool) async {
        guard canUpdate else { return }

        do {
            print("Received: \(editInfo.value)")

            print("Updating the status updates the entire view due ot the binding")
            updateStatus(.updating)
//            try await Task.sleep(for: .seconds(2))
//            throw NSError.quick("Testing Error")
            print("Before: \(info.value) - Update to: \(editInfo.value)")
            try await controller.sheetRow(.update, row: editInfo, from: contact)
            print("After: \(info.value)")

            if editAfterUpdate {
                updateStatus(.editing)
            } else {
                updateStatus(.idle)
            }
        } catch {
            updateStatus(.idle)
        }
    }
    func deleteContactSheetRow() async {
        do {
            updateStatus(.deleting)
            try await controller.sheetRow(.delete, row: editInfo, from: contact)
            updateStatus(.idle)
        } catch {
            updateStatus(.idle)
        }
    }
    
    func updateStatus(_ newStatus: NLF_Contact.SheetRow.Status) {
        guard info.status != newStatus  else { return }
        guard let index = controller.contacts.firstIndex(where: {$0.id == contact.id}) else { return }
        guard let rowIndex = controller.contacts[index].info.firstIndex(where: {$0.id == info.id}) else { return }
        contact.info[rowIndex].status = newStatus
//        info.status = newStatus
        editInfo = info
    }
}


//MARK: -View Builders
fileprivate extension NLF_Contact_Info_SheetRow {
    @ViewBuilder func editingView() -> some View {
            
        GridRow(alignment: .center) {
            NLF_Contact_SheetRow_Label(row:$editInfo, customLabels: []) { _ in
                Task {
                    await updateContactSheetRow(editAfterUpdate:true)
                }
            }
            .fixedSize()
            .padding(.trailing, 8)
            
            HStack {
                TextField("Value", text:$editInfo.value, prompt: Text("Enter value here"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onKeyPress { press in // Detect key presses
                       if press.key == .tab {
                           // Handle the Tab key press here
                           if editInfo.value != info.value {
                               print("Sending: \(editInfo.value)")

                               Task { await updateContactSheetRow(editAfterUpdate: true)}
                               return .handled // Indicate the key press is handled
                           } else {
                               return .ignored
                           }
                       }
                       return .ignored // Let other views handle it if not Tab
                   }
                    .onSubmit {
                        if editInfo.value != info.value {
                            Task { await updateContactSheetRow(editAfterUpdate: false)}
                        }
                    }
                    .foregroundStyle(editInfo.value != info.value ? Color.orange : Color.primary)
         
                if !isEditing {
                    Button("Done") {
                        if editInfo.value != info.value {
                            Task { await updateContactSheetRow(editAfterUpdate: false)}
                        } else {
                            updateStatus(.idle)
                        }
                    }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                }
                Button { Task {await deleteContactSheetRow() } } label: {Image(systemName: "trash")}
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
        }
            .textFieldStyle(.roundedBorder)
            .disabled(info.status != .editing)
    }
    @ViewBuilder func normalView(row:NLF_Contact.SheetRow) -> some View {
        GridRow(alignment: .center) {
            Text(row.label.isEmpty ? "No Label" : row.label)
                .foregroundStyle(.secondary)
                .fixedSize()
                .padding(.trailing, 8)
                .padding(.leading)

            HStack {
                if row.status != .idle {
                    Text_Progress(row.value.isEmpty ? "No Value" : row.value)
                } else {
                    Text(row.value.isEmpty ? "No Value" : row.value )
                }
            }
                .frame(maxWidth: .infinity, alignment: .leading)

        }
            .padding(.bottom, 2)
    }
    @ViewBuilder func menu() -> some View {
        if info.status == .idle {
//            Button("Edit") { updateStatus(.editing)  }
            Button("Edit") { showEditView.toggle() }
            Divider()
            Button("Delete             ") { showDeleteView.toggle() }
                .modifierKeyAlternate(.command) {
                    Button("Delete Now!") { Task { await deleteContactSheetRow() } }
                    
                }
        }
    }
}

