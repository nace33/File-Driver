//
//  NLF_Form_MultipleSelection.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/30/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct NLF_Form_MultipleSelection: View {
    var forms : [NLF_Form]
    enum Action : String, CaseIterable {
        case rename, status, category
    }
    @Environment(NFL_FormController.self)  var controller
    @State private var action : Action = .category
    @State private var isActing = false
    @State private var statusMessage : String = ""
    @State private var error : Error?
    @State private var label : NLF_Form.Label = NLF_Form.Label.new()
    @AppStorage(BOF_Settings.Key.formsMasterIDKey.rawValue)  var formDriveID : String = "0AGhFu4ipV3y0Uk9PVA"
   
    
    
    var body: some View {
        VStackLoader(alignment: .center, spacing: 10, title:"" , isLoading: $isActing, status: $statusMessage, error: $error) {
            if formDriveID.isEmpty {
                NLF_Form_DriveID()
            } else {
                Picker(selection: $action) {
                    ForEach(Action.allCases, id:\.self) { Text($0.rawValue.camelCaseToWords())}
                } label: {
                    Text("Multi-Form Actions").font(.title2)
                } currentValueLabel: {
                    Text(action.rawValue.camelCaseToWords())
                }
                .fixedSize()
                .pickerStyle(.segmented)
                
                Divider()
                switch action {
                case .rename:
                    Drive_Rename(files: forms.compactMap(\.file), title: "") { renamedFile, _ in
                        if let index = controller.forms.firstIndex(where: {$0.id == renamedFile.id}) {
                            controller.forms[index].title     = renamedFile.name ?? "No File Name"
                            controller.forms[index].file.name = renamedFile.name
                        }
                    }
                case .status:
                    Form {
                        Section {
                            LabeledContent("Status") {
                                NLF_Form_StatusPicker(label: $label, showStatusColor: false).labelsHidden()
                            }
                        }footer: {
                            HStack {
                                Spacer()
                                Button("Update Status") { Task { await updateStatus()  }}
                                    .buttonStyle(.borderedProminent)
                                    .disabled(!canUpdateStatus)
                            }
                        }
                    }.formStyle(.grouped)
                case .category:
                    Form {
                        Section {
                            NLF_Form_CategoryMenu(label: $label)
                        } footer: {
                            HStack {
                                Spacer()
                                Button("Update Categories") { Task { await updateCategory() }}
                                    .buttonStyle(.borderedProminent)
                                    .disabled(!canRecategorize)
                            }
                        }
                    }.formStyle(.grouped)
                }
            }
            Spacer()
                
        }
            .padding()
    }
    var canUpdateStatus : Bool {
        guard forms.filter({ $0.label.status != label.status}).count > 0 else { return false }
        return true
    }
    var canRecategorize : Bool {
        guard !label.category.isEmpty else { return false }
        guard forms.filter({ $0.file.driveId != formDriveID}).count == 0 else { return false }
        guard forms.filter({ $0.label.category == label.category && $0.label.subCategory == label.subCategory}).count == 0 else { return false}
        return true
    }
    
    func updateStatus() async {
        do {
            self.isActing = true
            let status = label.status
            for form in forms {
                if let index = controller.index(of: form) {
                    controller.forms[index].label.status = status
//                    _ = try await controller.update(file: form.file, label: form.labelModification)
                    _ =  try await Google_Drive.shared.label(modify: NLF_Form.DriveLabel.id.rawValue, modifications: [form.labelModification], on: form.file.id)
                }
            }
            
            self.isActing = false
        } catch {
            self.isActing = false
            self.error = error
        }
    }
    func updateCategory() async {
        do {
        
            self.isActing = true
            statusMessage = "Gathering folder infomation..."
            let destination = try await controller.getDestinationFolder(label:label, driveID:formDriveID)
            
            let category    = label.category
            let subCategory = label.subCategory
            for form in forms {
                if let index = controller.index(of: form) {
                    controller.forms[index].label.category    = category
                    controller.forms[index].label.subCategory = subCategory
                    
//                    _ = try await controller.update(file: form.file, label: form.labelModification)
                    statusMessage = "Updating label for \(form.file.title)..."
                    
                    _ =  try await Google_Drive.shared.label(modify: NLF_Form.DriveLabel.id.rawValue, modifications: [controller.forms[index].label.labelModification], on: form.file.id)
                    
                    statusMessage = "Moving \(form.file.title) to \(destination.title) ..."
                    let tempFile = try await Google_Drive.shared.move(file: form.file, to: destination)

                    if let possiblySameIndex = controller.index(of: form) {
                        controller.forms[possiblySameIndex].file.identifier = tempFile.identifier
                        controller.forms[possiblySameIndex].file.parents    = tempFile.parents
                    }
                }
            }
            
            self.isActing = false
        } catch {
            self.isActing = false
            self.error = error
        }
    }
}
