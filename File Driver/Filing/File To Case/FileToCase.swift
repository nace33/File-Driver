//
//  Filer_View.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/2/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct FileToCase: View {
    let items       : [FileToCase_Item]
    let isFiling    : (Bool)->Void
    let canceled    : (() -> Void)?
    let filed       : ([FileToCase_Item])->Void
    enum Action     : String, CaseIterable {
        case fileLater, cancel, addToCase
    }
    let actions : [Action]
    init(_ items:[FileToCase_Item], actions:[Action] = [.addToCase], isFiling:@escaping(Bool) -> Void,  filed:@escaping([FileToCase_Item])->Void, canceled:(()->Void)? = nil) {
        self.items = items
        self.canceled = canceled
        self.actions = actions
        self.filed = filed
        self.isFiling = isFiling
        _delegate = State(initialValue: FileToCase_Delegate())
    }
    @State private var delegate : FileToCase_Delegate
    @Environment(\.dismiss) var dismiss
    @AppStorage(BOF_Settings.Key.filingDrive.rawValue)       var driveID : String = ""
    @State private var showDriveSelector = false
    
    
    var body: some View {
        VStack(alignment:.leading, spacing:0) {
            VStackLoader(isLoading: $delegate.isLoading, status: $delegate.status, progress:$delegate.progress, error: $delegate.error) {
                if let error = delegate.error as? Filing_Error {
                    processError(error)
                } else {
                    delegate.error = nil
                }
            } header: {
                FileToCase_Header()
                Divider()
            } content: {
                if showDriveSelector {
                    driveSelector
                }
                else if delegate.showCasesList {
                    Filer_CaseList()
                } else if delegate.showFoldersList {
                    FileToCase_DriveList()
                } else {
                    FileToCase_Form()
                }
            }
            actionBar
        }
            .environment(delegate)
            .task(id:items) { delegate.items = items }
            .task           { await delegate.load()  }
            .onChange(of: delegate.isFiling, { oldValue, newValue in
                isFiling(newValue)
            })
            .onChange(of: delegate.justFiled) { oldValue, newValue in
                if let newValue {
                    isFiling(false)
                    filed(newValue)
                }
            }
    }
    
    func processError(_ error:Filing_Error) {
        switch error {
        case .filesMovedButSpreadsheetNotUpdated(_), .uploadFailed(_, _):
            Task {
                try? await delegate.retryUpdateSpreadsheet()
            }
        default:
            delegate.error = nil
        }
    }
    func fileLater() {
        Task {
            if let filedItems = await delegate.fileLater(driveID) {
                filed(filedItems)
            }
            if actions.contains(.cancel) {
                cancel()
            }
        }
    }
    func addToCase() {
        Task {
            if let filedItems = await delegate.addToCase() {
                filed(filedItems)
                delegate.items.removeAll()
                delegate.selectedDestination = nil
                delegate.stack.removeAll()
                delegate.selectedCase = nil
            }
            if actions.contains(.cancel) {
                cancel()
            }
        }
        
    }
    func cancel() {
        if let canceled {
            canceled()
        }
        dismiss()
    }
    @ViewBuilder var driveSelector : some View {
        DriveSelector("Select Filing Drive", canLoadFolders: false, mimeTypes: [.folder]) { selected in
            driveID = selected.id
            showDriveSelector = false
            fileLater()
        }
    }
    @ViewBuilder var actionBar : some View {
        if actions.count > 0 {
            Divider()
            HStack {
                if actions.contains(.fileLater), items.count > 0 {
                    Button("File Later") {
                        if driveID.isEmpty { showDriveSelector = true }
                        else {
                            fileLater()
                        }
                    }
                        .buttonStyle(.link)
                        .disabled(delegate.isFiling || delegate.isLoading)
                }
                Spacer()
                if actions.contains(.cancel) {
                    Button("Cancel") { cancel() }
                        .foregroundStyle(.red)
                        .buttonStyle(.link)
                        .padding(.trailing, 8)
                }
                if actions.contains(.addToCase) {
                    Button("Add to Case") {
                        addToCase()
                    }
                        .buttonStyle(.borderedProminent)
                        .disabled(!delegate.canAddToCase || delegate.isFiling || delegate.isLoading)

                }
            }
            .padding()
        }
    }
}

#Preview {
    let items : [FileToCase_Item] = {
       let file = GTLRDrive_File()
        file.identifier = "1oF_sroSp3aWlmsX2Oe0PRJ4LsoQIAkaQ"
        file.name = "Frodo Baggins.png"
        file.fileExtension = "png"
        file.descriptionProperty = "Wizard"
        return [.init(file)]
    }()
    FileToCase(items) { isFiling in print("\(isFiling)")} filed: {
        print("Filed: \($0)")
    }
        .environment(Google.shared)
        .modelContainer(BOF_SwiftData.shared.container)
        .frame(minWidth:600, minHeight: 600)
}
