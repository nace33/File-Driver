//
//  NLF_Form_DriveID.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/28/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct NLF_Form_DriveID: View {
    var alwaysShowUI : Bool = false
    @AppStorage(BOF_Settings.Key.formsMasterIDKey.rawValue)  var formDriveID : String = "0AGhFu4ipV3y0Uk9PVA"
    @State private var driveID = ""
    
    @State private var loading: Bool = false
    @State private var drives : [GTLRDrive_Drive] = []
    @State private var error: Error?
    @State private var selectedDrive : GTLRDrive_Drive?
    var body: some View {
        if formDriveID.isEmpty || alwaysShowUI {
            VStack(alignment: .leading) {
                if let error {
                    Text("Default 'Form' Shared Drive Error")
                    Text(error.localizedDescription)
                    Button("Try Again") { Task { await loadDrives() }}
                } else if loading { ProgressView("Loading Drives...")}
                else {
                    HStack {
                        Picker("Default 'Form' Drive", selection: $selectedDrive) {
                            if selectedDrive == nil {
                                Text("No Selection").tag(nil as GTLRDrive_Drive?)
                            }
                            ForEach(drives, id:\.self) { drive in
                                Text(drive.name ?? "No Name").tag(drive as GTLRDrive_Drive?)
                            }
                        }
                            .fixedSize()
                        if let driveID = selectedDrive?.id, driveID != formDriveID {
                            Button("Save") { formDriveID  = driveID }
                        }
                    }
                }
            }
            .padding(8)
            .task { await loadDrives() }
        }
    }
    
    func loadDrives() async {
        do {
            loading = true
            drives = try await Google_Drive.shared.sharedDriveList().drives ?? []
            if drives.isEmpty { throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "No Drives Found"])}
            loading = false
            selectedDrive = drives.first(where: {$0.id == formDriveID})
        } catch {
            loading = false
            self.error = error
        }
    }
}

#Preview {
    NLF_Form_DriveID(alwaysShowUI:true)
        .padding()
        .frame(minWidth: 300)
        .environment(Google.shared)
}
