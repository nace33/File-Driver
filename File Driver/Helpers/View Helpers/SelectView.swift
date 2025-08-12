//
//  SelectPopover.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/7/25.
//

import SwiftUI

public
struct SelectView<L:View, M:View>: View {
    private let title : String
    @Binding var filter : String
    private let list : () -> L
    private let menu : () -> M
    private let selected : (String) -> Bool //returning true dismisses the sheet, false does not dismiss the sheet
    private let showMenu : Bool
    public init(title: String, filter: Binding<String>, @ViewBuilder list: @escaping () -> L, @ViewBuilder menu: @escaping () -> M, selected: @escaping (String) -> Bool) {
        self.title = title
        _filter = filter
        self.list = list
        self.menu = menu
        self.selected = selected
        showMenu = true
        
    }
    public init(title: String, filter: Binding<String>, @ViewBuilder list: @escaping () -> L, selected: @escaping (String) -> Bool) where M == EmptyView {
        self.title = title
        _filter = filter
        self.list = list
        self.menu = {EmptyView() }
        self.selected = selected
        showMenu = false
    }
    
    @Environment(\.dismiss) var dismiss
    
    public var body: some View {
        VStack(alignment:.leading, spacing:0) {
            HStack {
                Text("Select \(title)")
                    .foregroundStyle(.secondary)
                    .font(.title2)
                    .bold()
                Spacer()
                TextField("Search \(title)s", text:$filter, prompt: Text("Filter"))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .frame(width:150)
                    .focusable(false)
                
            }
                .padding(.horizontal)
                .padding(.vertical, 10)
            
            Divider()
            
            list()
                .contextMenu(forSelectionType: String.self, menu: { items in
                    if let item = items.first {
                        Button("Select") {
                            select(item)
                        }
                        if showMenu { Divider()}
                    }
                    menu()
                }, primaryAction: { items in
                    if let item = items.first {
                        select(item)
                    }
                })
        }
            .presentationSizing(.fitted) // Allows resizing, sizes to content initially
            .frame(minWidth:400, minHeight:400)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
    }
    func select(_ root:String) {
        if selected(root) {
            dismiss()
        }
    }
}
