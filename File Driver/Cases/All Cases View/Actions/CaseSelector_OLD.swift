//
//  Case_Selector.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/18/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive


struct CaseSelector<Header:View, Content:View>: View {
    let suggestedIDs : [String]
    @ViewBuilder var header : () -> Header
    @ViewBuilder var content : (Case, GTLRDrive_File, [GTLRDrive_File]) -> Content
    
    init(_ suggestedIDs: [String] = [], @ViewBuilder header: @escaping () -> Header, @ViewBuilder content: @escaping (Case, GTLRDrive_File, [GTLRDrive_File]) -> Content) {
        self.suggestedIDs = suggestedIDs
        self.header = header
        self.content = content
    }
    init(_ suggestedIDs: [String] = [], @ViewBuilder content: @escaping (Case, GTLRDrive_File, [GTLRDrive_File]) -> Content) where Header == EmptyView {
        self.suggestedIDs = suggestedIDs
        self.header = { EmptyView() }
        self.content = content
    }
    
    @State private var cases : [Case]  = []
    @State private var caseFiles : [GTLRDrive_File] = []
    @State private var delegate = DriveDelegate(actions:[.filter, .select])
    @State private var destinationFolder : GTLRDrive_File?

    var body: some View {

     
        DriveView("Cases", delegate: $delegate) { folder in
            true
        } load: {
            try await load()
        } header: {
            if let destinationFolder {
                addToCaseHeader(destinationFolder)
            }
            else {
                DriveView_Header(title:"Cases")
            }
            Divider()
        } list: {
             if  let destinationFolder, let selectedCase {
                 //display the views passed into this view
                content(selectedCase, destinationFolder, delegate.stack)
            }
            else {
                DriveView_List { files in
                    if selectedCase == nil {
                        casesListSectionedBody(files)
                            .listRowSeparator(.hidden)
                    }
                    //selectedCase != nil before stack isLoading gets set.
                    //use stackWillReloadSoon to wait until reloading is occuring
                    else if !delegate.stackWillReloadSoon {
                        DriveView_ListBody(files)
                    }
                }
            }
        }
            .onChange(of: delegate.stack) { oldValue, newValue in
                //do not modify stack or selection since DriveView_List handles that
                destinationFolder = nil
                if newValue.isEmpty {
                    delegate.actions   = [.filter, .select]
                    delegate.mimeTypes = [.sheet]
                } else {
                    delegate.actions = [.newFolder, .filter, .select]
                    delegate.mimeTypes = [.folder]
                }
            }
            .onChange(of: delegate.selectItem) { oldValue, newValue in
                if let newValue {
                    if delegate.stack.isEmpty {
                        delegate.addToStack(newValue)
                    } else {
                        destinationFolder = newValue
                    }
                }
                else {
                    destinationFolder = nil
                }
            }
    }
}


//MARK: - Properties
fileprivate extension CaseSelector {
    var selectedCase : Case? {
        cases.first(where: {$0.label.folderID == delegate.stack.first?.id})
    }
}


//MARK: - Actions
fileprivate extension CaseSelector {
    func load() async throws -> [GTLRDrive_File] {
        do {
            if let last = delegate.stack.last {
                return try await Drive.shared.getContents(of:last.id, onlyFolders: true)

            } else {
                return try await loadCases()
            }
        } catch {
            throw error
        }
    }
    func loadCases() async throws -> [GTLRDrive_File] {
        do {
            cases = try await Drive.shared.get(filesWithLabelID:Case.DriveLabel.Label.id.rawValue)
                .sorted(by: {$0.title.lowercased() < $1.title.lowercased()})
                .compactMap { Case($0)}
            
            
            caseFiles = cases.compactMap { aCase in
                let file = GTLRDrive_File()
                file.identifier = aCase.folderID
                file.name = aCase.title
                file.mimeType = aCase.file.mimeType
                file.labelInfo = aCase.file.labelInfo
                return file
            }
         
            return caseFiles
            
        } catch {
            throw error
        }
    }
}


//MARK: - View Builders
fileprivate extension CaseSelector {
    @ViewBuilder func addToCaseHeader(_ destinationFolder: GTLRDrive_File) -> some View {
        HStack {
            DriveView_PathBar("Cases") {
                if delegate.stack.last != destinationFolder {
                    Image(systemName: "chevron.right")
                    Text(destinationFolder.title)
                }
            }
            Spacer()
            header()
        }
        //same modififers as DriveView_Header
        .frame(minHeight:22)
        .buttonStyle(.plain)
        .lineLimit(1)
        .padding(8)
    }
    @ViewBuilder func casesListSectionedBody(_ files:Binding<[GTLRDrive_File]>) -> some View {

        let suggestedFiles = files.filter {  suggestedIDs.contains($0.wrappedValue.id)}
        let normalFiles    = files.filter { !suggestedIDs.contains($0.wrappedValue.id)}
        if suggestedFiles.isNotEmpty {
            Section("Suggestions") {
                ForEach(suggestedFiles, id:\.wrappedValue.self) { file in
                    DriveView_Row(file)
                }
            }
        }
        
        
        let categories = normalFiles.compactMap { Case.DriveLabel(file: $0.wrappedValue)?.category}
            .unique()
            .sorted(by: {$0.intValue < $1.intValue})
       
        
        ForEach(categories, id:\.self) { category in
            let catFiles = normalFiles.filter {
                Case.DriveLabel(file: $0.wrappedValue)?.category == category
            }
            if catFiles.count > 0 {
                Section(category.title) {
                    ForEach(catFiles, id:\.wrappedValue.self) { file in
                        DriveView_Row(file)
                    }
                }
            }
        }
        
    }
    @ViewBuilder func casesListBody(_ files:Binding<[GTLRDrive_File]>) -> some View {
        ForEach(files, id:\.wrappedValue.self) { file in
            DriveView_Row(file)
        }
    }
}



//MARK: - Preview
#Preview {
    CaseSelector {
        Button("Add Too Case") { }
            .buttonStyle(.borderedProminent)
    } content: { aCase, folder, stack in
        Form {
            Text(aCase.title)
            ForEach(stack) { f in
                Text(f.title)
            }
            Text(folder.title)
        }
    }
    .environment(Google.shared)
}
