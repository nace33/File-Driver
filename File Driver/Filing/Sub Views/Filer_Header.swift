//
//  Filer.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/21/25.
//


import SwiftUI
import BOF_SecretSauce


struct Filer_Header : View {
    @Environment(Filer_Delegate.self) var delegate
    @State private var showNewCaseSheet     = false
    @State private var showNewFolderSheet   = false
    
    
    var body : some View {
        HStack {
     
            Picker("Save To", selection: Bindable(delegate).mode) {
                ForEach(Filer_Delegate.Mode.allCases, id:\.self) { mode in
                    Text(mode.rawValue.capitalized)
                }
            }
                .fixedSize()
                .labelsHidden()
            
            ForEach(delegate.stack, id:\.self) { stackFolder in
                Button(stackFolder.title) {
                    delegate.popTo(stackFolder)
                }
                    .buttonStyle(.plain)
                if stackFolder != delegate.stack.last {
                    Image(systemName:"chevron.right")
                }
            }
            
            if !delegate.canShowForm {
                addNewButton
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                
                Spacer()
                
                filterTextField
                    .frame(maxWidth:150)
                    .textFieldStyle(.roundedBorder)
                

            }
        }
            .disabled(delegate.items.isEmpty || delegate.loader.isLoading)
            .frame(minHeight:38)
            .padding(.horizontal)
            .lineLimit(1)
            .sheet(isPresented: $showNewCaseSheet  ) { newCaseView   }
            .sheet(isPresented: $showNewFolderSheet) { newFolderView }
    }
    

    //Actions
    func addButtonClicked() {
        switch delegate.mode {
        case .cases:
            if delegate.selectedCase == nil {
                showNewCaseSheet = true
            } else {
                showNewFolderSheet = true
            }
        case .folders:
            showNewFolderSheet = true
        }
    }
    ///Reset
    func resetButtonPressed() {
        delegate.resetCaseVariables()
        delegate.resetFolderVariables()
        Task { await delegate.load() }
    }
    
    //Sheets
    @ViewBuilder var addNewButton    : some View {
        switch delegate.mode {
        case .cases:
            if delegate.selectedCase == nil, delegate.actions.contains(.newCase) {
                Button { addButtonClicked() } label: { Image(systemName: "plus")  }
            }
            else if delegate.selectedCase != nil, delegate.actions.contains(.newFolder) {
                Button { addButtonClicked() } label: { Image(systemName: "plus")  }
            } else {
                EmptyView()
            }
        case .folders:
            if delegate.stack.isEmpty && delegate.actions.contains(.newDrive) {
                Button { addButtonClicked() } label: { Image(systemName: "plus")  }
            }
            else if delegate.stack.isNotEmpty && delegate.actions.contains(.newFolder){
                Button { addButtonClicked() } label: { Image(systemName: "plus")  }
            } else {
                EmptyView()
            }
        }
    }
    @ViewBuilder var filterTextField : some View {
        switch delegate.mode {
        case .cases:
            if delegate.selectedCase == nil && delegate.actions.contains(.filterCases) {
                TextField("Filter", text:Bindable(delegate).filterString)
            } else if delegate.selectedCase != nil && delegate.actions.contains(.filterFolders) {
                TextField("Filter", text:Bindable(delegate).filterString)
            } else {
                EmptyView()
            }
        case .folders:
            if delegate.stack.isEmpty && delegate.actions.contains(.filterDrive) {
                TextField("Filter", text:Bindable(delegate).filterString)
            } else if delegate.stack.isNotEmpty && delegate.actions.contains(.filterFolders) {
                TextField("Filter", text:Bindable(delegate).filterString)
            } else {
                EmptyView()
            }
        }
    }
    @ViewBuilder var newCaseView     : some View {
        NewCase {
            delegate.addNewCase($0)
        }
    }
    @ViewBuilder var newFolderView   : some View {
        TextSheet(title:delegate.stack.last == nil ? "New Drive" : "New Folder", prompt: "Create") { name in
            do {
                try await delegate.addNewFolder(name)
                return nil
            } catch {
                return error
            }
        }
    }
}

#Preview {
    @Previewable @State var delegate = Filer_Delegate()
    Filer_Header()
//        .environment(Google.shared)
        .environment(delegate)
}
