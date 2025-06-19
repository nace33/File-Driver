//
//  ContactDetail_Info.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/12/25.
//

import SwiftUI
import BOF_SecretSauce



struct ContactDetail_Info: View {
    @Environment(Contact.self) var contact
    @State private var error: Error?
    enum Field { case label, value}
    @FocusState private var focusedField: Field?
    
    var body: some View {
        ForEach(contact.infoCategories, id:\.self) { category in
            categoryGridRow(category)
                .padding(.top, category != contact.infoCategories.first ? 12 : 0)
            
            ForEach(Bindable(contact).infos.filter { $0.wrappedValue.category == category}) { info in
                infoGridRow(info)
                    .padding(.bottom, 4)
            }
        }
    }
}


//MARK: - Actions
extension ContactDetail_Info {
    func create(_ category:String)  {
        Task {
            do {
                try await contact.createInfo(category:category)
            } catch {
                self.error = error
            }
        }
    }
    func edit(_ info:Binding<Contact.Info>, field:Field)  {
        contact.resetOtherEditingInfos()
        info.wrappedValue.status = .editing
        focusedField = field
    }
    func update(_ info:Binding<Contact.Info>) {
        Task {
            do {
              _ = try await contact.update(info)
            } catch {
                self.error = error
            }
        }
    }
    func delete(_ info:Binding<Contact.Info>)  {
        Task {
            do {
                try await contact.delete(info)
            } catch {
                self.error = error
            }
        }
    }
}


//MARK: - View Builders
extension ContactDetail_Info {
    @ViewBuilder func categoryGridRow(_ category:String) -> some View {
        GridRow {
            Text(" ")
            HStack {
                Button(category.uppercased()) {
                    create(category)
                }
                    .buttonStyle(.plain)
                    .bold()
                    .font(.caption)
                    .foregroundStyle(.blue)
                Spacer()
            }
        }
    }
    @ViewBuilder func infoGridRow(_ contactInfo:Binding<Contact.Info>) -> some View {
        GridRow(alignment: .top) {
            switch contactInfo.wrappedValue.status {
            case .creating:
                infoGridCreatingRow(contactInfo)
            case .idle:
                infoGridNormalRow(contactInfo)
            case .editing, .updating:
                infoGridEditRow(contactInfo)
                    .disabled(contactInfo.wrappedValue.status == .updating)
            case .deleting:
                infoGridDeleteRow(contactInfo)
            }
        }
        .contextMenu { menu(contactInfo)}
    }
    @ViewBuilder func infoGridCreatingRow(_ contactInfo:Binding<Contact.Info>) -> some View {
        Text(contactInfo.wrappedValue.label)
            .padding(.trailing, 8)
            .padding(.leading)
            .foregroundStyle(.secondary)

        Text_Progress("Creating")
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.secondary)
    }
    @ViewBuilder func infoGridNormalRow(_ contactInfo:Binding<Contact.Info>) -> some View {
        Text(contactInfo.wrappedValue.label.isEmpty ? "No Label" : contactInfo.wrappedValue.label)
            .foregroundStyle(.secondary)
            .padding(.trailing, 8)
            .padding(.leading)
            .onTapGesture(count:2) {
                edit(contactInfo, field: .label)
            }
    
        Text(contactInfo.wrappedValue.value.isEmpty ? "No Value" : contactInfo.wrappedValue.value)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture(count:2) {
                edit(contactInfo, field: .value)
            }
    }
    @ViewBuilder func infoGridEditRow(_ contactInfo:Binding<Contact.Info>) -> some View {
            HStack(spacing:0) {
                let suggestedLabels = contactInfo.wrappedValue.suggestedLabels
                TextField("Label", text:contactInfo.label, prompt: Text("Enter a label"))
                    .fixedSize()
                    .focused($focusedField, equals: .label)
                    .padding(.leading)
                    .padding(.trailing, suggestedLabels.isEmpty ? 8 : 0)
                    .onSubmit {
                        update(contactInfo)
                    }
                
                if !suggestedLabels.isEmpty {
                    Menu {
                        ForEach(suggestedLabels, id:\.self) { label in
                            Button(label) {
                                contactInfo.wrappedValue.label = label
                                update(contactInfo)
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                        .fixedSize()
                        .menuIndicator(.hidden)
                        .menuStyle(.borderlessButton)
                }
            }
        
            HStack {
                TextField("Value", text:contactInfo.value, prompt: Text("Enter a value"), axis: .vertical)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .focused($focusedField, equals: .value)
                    .onSubmit {
                        update(contactInfo)
                    }
                    .task(id:contactInfo.wrappedValue.id) {
                        if focusedField == nil { focusedField = .value}
                    }
                if contactInfo.wrappedValue.status == .updating {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width:16, height:16)
                } else {
                    Button("Cancel") { contactInfo.wrappedValue.status = .idle }
                        .font(.subheadline)
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                }
            }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing)
        
         
    }
    @ViewBuilder func infoGridDeleteRow(_ contactInfo:Binding<Contact.Info>) -> some View {
        GridRow(alignment: .top) {
            Text("Deleting")
                .padding(.trailing, 8)
                .padding(.leading)
            
            Text_Progress(contactInfo.wrappedValue.value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
            .foregroundStyle(.red)
    }
    @ViewBuilder func menu(_ contactInfo:Binding<Contact.Info>) -> some View {
        switch contactInfo.wrappedValue.status {
        case .idle:
            Button("Edit") {
                edit(contactInfo, field: .value)
            }
                .modifierKeyAlternate(.command) {
                    Button("Edit in Google Sheets") {
                        File_DriverApp.createWebViewTab(url: contact.file.editURL, title: contact.label.name)
                    }
                }
            Divider()
            Button("Delete") {
                delete(contactInfo)
            }
        default:
            EmptyView()
        }
    }

}
