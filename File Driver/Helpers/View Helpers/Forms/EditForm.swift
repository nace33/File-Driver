//
//  EditForm.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/11/25.
//


import SwiftUI

public
struct EditForm<T: Equatable, V:View, S:View> : View {

    let title : String
    let prompt : String
    var style : Style
    @Binding var item  :T
    @ViewBuilder var header  : () -> S
    @ViewBuilder var content : (Binding<T>) -> V
    var canUpdate : ((Binding<T>) -> Bool)?
    ///The item passed in is the unedited version
    ///already have access to the bound version
    var update : (Binding<T>) async throws -> Void
    public enum Style { case sheet, inline}
    
    public init(title: String = "Edit", prompt:String = "Update", style:Style = .sheet, item: Binding<T>, @ViewBuilder content: @escaping (Binding<T>) -> V, canUpdate:((Binding<T>) -> Bool)? = nil, update: @escaping (Binding<T>) async throws -> Void) where S == EmptyView {
        self.title = title.isEmpty ? " " : title
        _item = item
        self.style = style
        self.header = {EmptyView()}
        self.content = content
        self.update = update
        self.prompt = prompt
        self.canUpdate = canUpdate
        _editItem = State(initialValue: item.wrappedValue)
    }
    public init(prompt:String = "Update", style:Style = .sheet, item: Binding<T>, @ViewBuilder header: @escaping() -> S, @ViewBuilder content: @escaping (Binding<T>) -> V, canUpdate:((Binding<T>) -> Bool)? = nil, update: @escaping (Binding<T>) async throws -> Void) {
        self.title = ""
        self.header = header
        self.style = style
        _item = item
        self.content = content
        self.update = update
        self.prompt = prompt
        self.canUpdate = canUpdate
        _editItem = State(initialValue: item.wrappedValue)
    }
    
    @Environment(\.dismiss) var dismiss
    @State private var editItem : T
    @State private var isLoading = false
    @State private var error : Error?
    public
    var body: some View {
        Form {
            Section {
                content($editItem)
            } header: {
                HStack {
                    if title.isEmpty {
                        header()
                    } else {
                        Text(title)
                            .font(.title2)
                    }
                    Spacer()
                    if isLoading {
                        ProgressView()
                    }
                }.frame(minHeight: 32)
            } footer: {
                HStack {
                    Spacer()
                    VStack(alignment:.trailing) {
                        if style == .inline {
                            Button(prompt) { Task { await internalUpdate() } }
                                .buttonStyle(.borderedProminent)
                                .disabled(!canSendUpdate)
                        }
                        if let error {
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                   
                }
            }
        }
            .formStyle(.grouped)
//            .onSubmit {
//                guard canSendUpdate else { return }
//                Task { await internalUpdate() }
//            }
            .toolbar {
                if style == .sheet {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(prompt) { Task { await internalUpdate() } }
                            .disabled(!canSendUpdate)
                    }
                }
            }
            .disabled(isLoading)

    }
    var canSendUpdate : Bool {
        guard let canUpdate else { return true}
        return canUpdate($editItem)
    }
    func internalUpdate() async {
        do {
            self.error = nil
            self.isLoading = true
            try await update($editItem)
            self.item = editItem
            if style == .sheet {
                dismiss()
            } else {
                self.isLoading = false
            }
        } catch {
            //rever to original value if failure
            //Since editItem is not updated, not an issue
            self.isLoading = false
            self.error = error
        }
    }
}
