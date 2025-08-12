//
//  Contacts_DriveID.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct Drive_SetDefaultID : View {
    let title : String
    let key : String
    init(title:String, key:String) {
        self.title = title
        self.key = key
        let userDefaultString =  UserDefaults.standard.string(forKey: key)
        _savedDriveID = State(initialValue:userDefaultString ?? "")
    }
    
    
    @State private var savedDriveID : String
    @State private var isLoading: Bool = false
    @State private var drives : [GTLRDrive_Drive] = []
    @State private var status = ""
    @State private var error: Error?
    @State private var selectedDrive : GTLRDrive_Drive?
    @State private var validatedDrive : GTLRDrive_Drive?
    
    var body: some View {
        VStackLoader(isLoading: $isLoading, status: $status, error: $error) {
            HStack {
                Text(title).font(.title2)
                Spacer()
                if  validatedDrive != nil {
                    Button("Select Different Drive") { invalidate()}
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                } else {
                    if let selectedDrive {
                        Button("Select \(selectedDrive.title)") { select(drive:selectedDrive)}
                            .buttonStyle(.borderedProminent)
                    }
                }

            }.padding()
            Divider()
        } content: {
            if let validatedDrive {
                List {
                    Text("Status:\tDrive Validated")
                        .foregroundStyle(.green)
                    Text("Title:\t\(validatedDrive.title)")
                    Text("ID:\t\t\(validatedDrive.id)")
                }
                .listRowSeparator(.hidden)
            } else {
                List(drives, id: \.self, selection: $selectedDrive) { drive in
                    Text(drive.title)
                }
                .listRowSeparator(.hidden)
         
            }
        }
            .task { await validate() }
            .frame(height: 400)
    }
    func invalidate() {
        UserDefaults.standard.set(nil, forKey: key)
        UserDefaults.standard.synchronize()
        self.validatedDrive = nil
        Task { await loadSharedDrives() }
    }
    func select(drive:GTLRDrive_Drive) {
        UserDefaults.standard.set(drive.id, forKey: key)
        UserDefaults.standard.synchronize()
        
        self.validatedDrive = drive
    }
    func validate() async {
        do {
            status = "Validating..."
            isLoading = true
            validatedDrive = try await Drive.shared.sharedDrive(get: savedDriveID)
            isLoading = false
        } catch {
            if error.localizedDescription == Google_Error.driveCallSuceededButReturnTypeDoesNotMatch.localizedDescription {
                await loadSharedDrives()
            } else {
                isLoading = false
                status = ""
                self.error = error
            }
        }
    }
    func loadSharedDrives() async {
        do {
            isLoading = true
            status = "Getting Shared Drives..."
            if let drives = try await Drive.shared.sharedDriveList().drives {
                self.drives = drives
            } else {
                if drives.isEmpty { throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "No Drives Found"])}
            }
            status = ""
            isLoading = false
        } catch {
            isLoading = false
            status = ""
            self.error = error
        }
    }
}


#Preview {
    Drive_SetDefaultID(title: "Default Contacts Drive", key: BOF_Settings.Key.contactsDriveID.rawValue)
        .padding()
        .frame(minWidth: 300)
        .environment(Google.shared)
}
