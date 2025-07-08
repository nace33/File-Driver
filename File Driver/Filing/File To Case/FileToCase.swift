//
//  Filer_View.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/2/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct FileToCase: View {
    let files : [GTLRDrive_File]
    let isFiling : (Bool)->Void
    let filed : ([GTLRDrive_File])->Void
    
    init(_ files:[GTLRDrive_File], isFiling:@escaping(Bool) -> Void,  filed:@escaping([GTLRDrive_File])->Void) {
        self.files = files
        self.filed = filed
        self.isFiling = isFiling
        _delegate = State(initialValue: FileToCase_Delegate())
    }
    @State private var delegate : FileToCase_Delegate
    
    
    var body: some View {
        VStackLoader(isLoading: $delegate.isLoading, status: $delegate.status, error: $delegate.error) {
            if let error = delegate.error as? Filing_Error {
                processError(error)
            } else {
                delegate.error = nil
            }
        } header: {
            FileToCase_Header()
            Divider()
        } content: {
            if delegate.showCasesList {
                Filer_CaseList()
            } else if delegate.showFoldersList {
                FileToCase_DriveList()
            } else {
                FileToCase_Form()
            }
        }
            .environment(delegate)
            .task(id:files) { delegate.files = files }
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
        case .filesMovedButSpreadsheetNotUpdated(_):
            Task {
                try? await delegate.retryUpdateSpreadsheet()
            }
        default:
            delegate.error = nil
        }
    }
}

#Preview {
    let files : [GTLRDrive_File] = {
       let file = GTLRDrive_File()
        file.identifier = "1oF_sroSp3aWlmsX2Oe0PRJ4LsoQIAkaQ"
        file.name = "Frodo Baggins.png"
        file.fileExtension = "png"
        file.descriptionProperty = "Wizard"
        return [file]
    }()
    FileToCase(files) { isFiling in print("\(isFiling)")} filed: {
        print("Filed: \($0)")
    }
        .environment(Google.shared)
        .modelContainer(BOF_SwiftData.shared.container)
        .frame(minWidth:600, minHeight: 600)
}
