//
//  Filer_Header.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/2/25.
//

import SwiftUI
import BOF_SecretSauce

struct FileToCase_Header: View {
    @Environment(FileToCase_Delegate.self) var delegate
    @State private var showNewFolderSheet = false
    @State private var showNewCaseSheet = false
    
    var body: some View {
        HStack {
            Button("Cases") { delegate.pop(to: nil)}
            if delegate.stack.isEmpty {
                Button { showNewCaseSheet = true } label : { Image(systemName: "plus")}
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
            } else {  Image(systemName: "chevron.right")  }
            
        
            ForEach(delegate.stack, id:\.self) {folder in
                Button(folder.title) { delegate.pop(to: folder) }
                if folder != delegate.stack.last { Image(systemName: "chevron.right")}
                else if delegate.selectedDestination == nil {
                    Button {showNewFolderSheet = true } label: { Image(systemName: "plus")}
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                }
            }
            if let destination = delegate.selectedDestination, destination.id != delegate.stack.last?.id {
                Image(systemName: "chevron.right")
                Text(destination.title).foregroundStyle(.secondary)
            }
    
            Spacer()

            if delegate.showCasesList  {
                TextField("Filter", text: Bindable(delegate).filter)
                    .frame(maxWidth: 150)
                    .textFieldStyle(.roundedBorder)
            }
            selectButton
                .disabled(delegate.error != nil)
                .layoutPriority(1)
                .fixedSize()
        }
            .frame(maxWidth:.infinity, minHeight:22)
            .disabled(delegate.isLoading )
            .buttonStyle(.plain)
            .lineLimit(1)
            .padding(8)
            .background(.background)
            .sheet(isPresented: $showNewCaseSheet  ) { newCaseView }
            .sheet(isPresented: $showNewFolderSheet) { newFolderView }
    }
}


//MARK: - View Builders
extension FileToCase_Header {
    @ViewBuilder var  pathPicker    : some View {
        Spacer()
        Menu {
            ForEach(delegate.stack, id:\.self) {folder in
                Button(folder.title) { delegate.pop(to: folder) }
//                if folder != delegate.stack.last { Image(systemName: "chevron.right")}
//                else if delegate.selectedDestination == nil {
//                    Button {showNewFolderSheet = true } label: { Image(systemName: "plus")}
//                        .buttonStyle(.plain)
//                        .foregroundStyle(.blue)
//                }
            }
        } label: {
            if let destination = delegate.selectedDestination, destination.id != delegate.stack.last?.id {
                Image(systemName: "chevron.right")
                Text(destination.title).foregroundStyle(.secondary)
            } else if let last = delegate.stack.last {
                Button(last.title) { delegate.pop(to: last) }
            }
        }
    }
    @ViewBuilder var  selectButton  : some View {
        if delegate.stack.isEmpty {
            Button("Select") { delegate.doubleClicked(delegate.selectedCase!) }
                .buttonStyle(.borderedProminent)
                .disabled(delegate.selectedCase == nil )
        } else if delegate.selectedDestination == nil {
            Button("Select") { delegate.select(delegate.selectedFolder!)      }
                .buttonStyle(.borderedProminent)
                .disabled(delegate.selectedFolder == nil )
        } else {
            EmptyView()
        }
    }
    @ViewBuilder var  addToCaseButton  : some View {
        Button("Add to Case") { Task { await delegate.addToCase() } }
            .buttonStyle(.borderedProminent)
            .disabled(!delegate.canAddToCase)
    }
    @ViewBuilder var  newCaseView   : some View {
        NewCase { newCase in
            delegate.addNewCase(newCase)
        }
    }
    @ViewBuilder var  newFolderView : some View {
        TextSheet(title: "New Folder", prompt: "Create") { name in
            do {
                guard let parentID = delegate.stack.last?.id else { throw NSError.quick("No Parent ID")}
                try await delegate.addNewFolder(name, parentID:parentID)
                return nil
            } catch {
                return error
            }
        }
    }
}
