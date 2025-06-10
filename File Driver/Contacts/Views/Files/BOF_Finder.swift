//
//  BOF_Finder.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/5/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive


public struct BOF_Finder : View {
    let rootID : String?
    var filter : ([GTLRDrive_File] ) -> [GTLRDrive_File]
    @State private var files : [GTLRDrive_File] = []
    @State private var stack : [GTLRDrive_File] = []
    @State private var state : DriveState  = .idle

    
    public var body: some View {
        VStackLoader(isLoading:isLoading, status: .constant(""), error:error) {
            Text("Hello")
        } content: {
            List {
                ForEach(files) { file in
                    Label { Text(file.title) } icon: { file.icon }
                }
            }.frame(minHeight: 200, maxHeight: .infinity)
        }
        .task(id:rootID) { Task { await load() }}
        .task(id:stack ) { Task { await load() }}
    }
}



//MARK: -Actions
extension BOF_Finder {
    var loadID : String? {
        if let last = stack.last {
            last.id
        } else if let rootID, !rootID.isEmpty {
            rootID
        } else {
            nil
        }
    }
    func load() async {
        do {
            state = .loading
            
            let preFilteredFiles = if let loadID {
                try await Google_Drive.shared.getContents(of:loadID)
            } else {
                try await Google_Drive.shared.sharedDrivesAsFolders()
            }
            print("FilesA: \(preFilteredFiles.count)")
            files = filter(preFilteredFiles)
                          .sorted { $0.title.ciCompare($1.title)}
            print("FilesA: \(files.count)")
            state = .idle
           
        } catch {
            state = .error(error)
        }
    }
}



//MARK: -Actions
extension BOF_Finder {
    var isLoading : Binding<Bool> { Binding(get: {state == .loading }, set: {_ in })}
    var status    : String {
        switch state {
        case .idle:
            "Idle"
        case .loading:
            "Loading..."
        case .error(_):
            "Error"
        }
    }
    var error     : Binding<Error?> { Binding(get: {
        switch state {
        case .error(let error):
            error
        default:
            nil
        }
    }, set: {_ in })}
    public enum DriveState :Equatable {
        public static func == (lhs: BOF_Finder.DriveState, rhs: BOF_Finder.DriveState) -> Bool {
            lhs.intValue == rhs.intValue
        }
        
        case idle, loading, error(Error)
        var intValue : Int {
            switch self {
            case .idle:
                0
            case .loading:
                1
            case .error(_):
                2
            }
        }
    }
}
