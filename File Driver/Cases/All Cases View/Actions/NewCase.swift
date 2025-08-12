//
//  NewCase.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
struct NewCase: View {
    @Environment(\.dismiss) var dismiss
    var created : (Case) -> Void
    
    @State private var title = ""
    @State private var category : Case.DriveLabel.Label.Field.Category = .workersCompensation
    @State private var status   : Case.DriveLabel.Label.Field.Status   = .consultation
    //No open or closed properties.  (1) opened is today, (2) closed makes no sense in the context of making a new case
    //FolderID is the root folder where the case is saved.
    //Likely should be a new shared drive for non-consultation/investigation type cases
    @State private var folderID : String               = ""
    @State private var createSharedDrive = false
    @State private var isCreating = false
    @State private var statusString = ""
    @State private var error: Error?
    
    @State private var driveFile : GTLRDrive_File = GTLRDrive_File()
    @State private var showDrivePicker : Bool = false
    
   

    var body: some View {
        VStackLoader(title: "New Case", isLoading: $isCreating, status: $statusString, error: $error) {
            newCaseForm
        }
            .frame(minWidth: 250, minHeight: 300)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Create") { Task { await create() } }
                        .disabled(!canCreate)
                }
            }
            .disabled(isCreating)
    }
}


//MARK: -Properties
extension NewCase {
    var canCreate : Bool {
        guard !title.isEmpty    else { return false }
        guard !folderID.isEmpty || createSharedDrive else { return false }
        return true
    }

}


//MARK: -Actions
extension NewCase {
    func create() async {
        do {
            self.isCreating = true
            var caseLabel = Case.DriveLabel(title: title, category: category, status: status, opened: Date(), closed: nil, folderID: "")

            let caseFolder : GTLRDrive_File
            if createSharedDrive {
                self.statusString = "Creating Shared Drive"
                let newDrive = try await Drive.shared.sharedDrive(new: caseLabel.folderTitle)
                caseFolder = newDrive.asFolder
            } else {
                self.statusString = "Creating Case Folder"
                caseFolder = try await Drive.shared.create(folder: caseLabel.folderTitle, in: folderID, mustBeUnique: true)
            }
            caseLabel.folderID  = caseFolder.id

            self.statusString = "Creating Case Spreadsheet"
            let newCaseFile = try await Drive.shared.create(fileType: .sheet, name: caseLabel.sheetTitle, parentID: caseFolder.id, description: Case.spreadsheetVersion)
            
            self.statusString = "Installing Sheets"
            let sheets = Case.Sheet.allCases.compactMap { $0.gtlrSheet }
            try await Sheets.shared.initialize(id:newCaseFile.id, gtlrSheets:sheets)
      
            self.statusString = "Applying Headers"
            _ = try await Sheets.shared.addHeaders(Case.Sheet.allCases.compactMap(\.headerRow), in:  newCaseFile.id)
            
            self.statusString = "Applying Named Ranges"
            _ = try await Sheets.shared.addNamedRanges(Case.Sheet.allCases.compactMap({$0.namedRanges}).flatMap({$0}), in: newCaseFile.id)
            
            self.statusString = "Formatting Spreadsheet"
            _ = try await Sheets.shared.format(wrap: .clip, vertical: .top, horizontal: .left, sheets:Case.Sheet.allCases.map(\.intValue), in: newCaseFile.id)
            
            self.statusString = "Creating Drive Label"
            let labelID = Case.DriveLabel.Label.id.rawValue
            _ = try await Drive.shared.label(modify: labelID, modifications:[caseLabel.labelModification], on: newCaseFile.id)
           
            self.statusString = "Success!"
            let newCase = Case(file: newCaseFile, label: caseLabel)
            created(newCase)
            dismiss()
        } catch {
            self.isCreating = false
            self.error = error
        }
    }
}



//MARK: -View Builders
extension NewCase {

    @ViewBuilder var newCaseForm : some View {
        Form {
            TextField("Name", text: $title)
            Picker("Type", selection: $category) {
                ForEach(Case.DriveLabel.Label.Field.Category.allCases, id: \.self) { category in
                    Text(category.title)
                }
            }
            Picker("Status", selection: $status) {
                ForEach(Case.DriveLabel.Label.Field.Status.allCases, id: \.self) { status in
                    Text(status.title)
                }
            }
            Toggle("Save to New Shared Drive", isOn: $createSharedDrive)
                .onChange(of: createSharedDrive) { oldValue, newValue in
                    folderID = ""
                    driveFile = GTLRDrive_File()
                }
            if !createSharedDrive {
               selectDriveView
            }
        }
        .formStyle(.grouped)
    }
    @ViewBuilder var selectDriveView : some View {
        LabeledContent("Save to") {
            Button(driveFile.name ?? "Select Drive") {
                showDrivePicker = true
            }
            .popover(isPresented: $showDrivePicker, arrowEdge: .bottom) {
                DriveSelector("Select Drive", canLoadFolders: true, file: $driveFile, mimeTypes: [.folder])
                    .onChange(of: driveFile) { oldValue, newValue in
                        folderID = driveFile.id
                        showDrivePicker = false
                    }
                    .frame(minWidth: 250, minHeight: 300)
            }
        }
    }
}


//MARK: - Preview
#Preview {
    NewCase() { _ in }
}

