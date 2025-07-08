//
//  TemplatesDetail.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
struct TemplatesDetail: View {
    let ids : Set<Template.ID>
    init(ids : Set<Template.ID>) {
        self.ids = ids
        _template = State(initialValue: Template.new())
    }
    @Environment(TemplatesController.self) var controller
 
    enum Action : String, CaseIterable {
        case  status, category, rename
    }
    @State private var action : Action = .status
    @State private var isActing = false
    @State private var statusMessage : String = "Edit Templates"
    @State private var error : Error?
   
    @State private var template : Template
    
    @AppStorage(BOF_Settings.Key.templateDriveID.rawValue)        var driveID       : String = ""

    var templates : [Template] {
        controller.templates.filter { ids.contains($0.id )}
                            .sorted(by:{ $0.title.ciCompare($1.title)})
    }

    var body: some View {
        VStackLoader(alignment: .center, spacing: 10, title:"" , isLoading: $isActing, status: $statusMessage, error: $error) {
            switch action {
            case .rename:
                Drive_Rename(title:"", sectionTitle:statusMessage, files:templates.compactMap(\.file), saveOnServer: true) { renamedFiles in
                    for renamedFile in renamedFiles {
                        if let index = controller.index(of: renamedFile.id) {
                            controller.templates[index].file.name = renamedFile.name
                            controller.templates[index].label.filename = renamedFile.title
                        }
                    }
                }
            case .status, .category:
                EditForm(title:statusMessage, prompt: "Update", style: .inline, item: $template) { editItem in
                    Group{
                        if action == .category {
                            TextField_Suggestions("Category", text: editItem.label.category, prompt:Text("Enter category"), suggestions: controller.allCategories)
                            TextField_Suggestions("Sub-Category", text: editItem.label.subCategory, prompt:Text("Optional"), suggestions: controller.subCategoriesOfCategory(editItem.wrappedValue.label.category))
                        }
                        if action == .status {
                            Picker("Status", selection: editItem.label.status) {
                                ForEach(Template.DriveLabel.Status.allCases, id:\.self) { Text($0.title).tag($0)}
                            }
                        }
                    }
                        .task(id:ids) {
                          loadDefaultValues(editItem: editItem)
                        }
                } canUpdate: { editItem in
                    canUpdateTemplate(editItem.wrappedValue)
                } update: { editItem in
                    switch action {
                    case .status:
                        await updateStatus(editItem.wrappedValue)
                    case .category:
                        await updateCategory(editItem.wrappedValue)
                    case .rename:
                        break
                    }
                }
            }
            
        }
     
    
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Picker(selection: $action) {
                        ForEach(Action.allCases, id:\.self) { Text($0.rawValue.camelCaseToWords())}
                    } label: {
                        Text("Multi-Form Actions").font(.title2)
                    } currentValueLabel: {
                        Text(action.rawValue.camelCaseToWords())
                    }
                        .pickerStyle(.segmented)
                }
            }
    }
    func loadDefaultValues(editItem:Binding<Template>) {
        let templates = templates
        if let sta = templates.first?.label.status, templates.allSatisfy({ $0.label.status == sta }) {
            editItem.wrappedValue.label.status = sta
            template.label.status = sta
            print("Status: \(sta.title)")
        }
        if let cat = templates.first?.label.category, templates.allSatisfy({ $0.label.category == cat }) {
            editItem.wrappedValue.label.category = cat
            template.label.category = cat
            print("Category: \(cat)")
        }
        if let sub = templates.first?.label.subCategory, templates.allSatisfy({ $0.label.subCategory == sub }) {
            editItem.wrappedValue.label.subCategory = sub
            template.label.subCategory = sub
            print("subCategory: \(sub)")
        }
    }
    func updateStatus(_ editItem:Template) async {
        do {
            let labelMods : [(mod:[GTLRDrive_LabelModification], fileID:String)] =  ids.compactMap { id in
                if let index = controller.index(of: id) {
                    let id       = controller.templates[index].id
                    var label    = controller.templates[index].label
                    label.status = editItem.label.status
                    return (mod:[label.labelModification], fileID:id)
                }
                return nil
            }
            statusMessage = "Updating Drive Labels"
            let labelResult = try await Drive.shared.label(modify: Template.DriveLabel.id.rawValue, modifications: labelMods)
            
            //Update Local Model
            if  labelResult.successes == nil ||  labelResult.successes?.count != labelMods.count{
                throw Template_Error.unableToUpdateCategory
            }
            for id in ids {
                if let index = controller.index(of: id) {
                    controller.templates[index].label.status    = editItem.label.status
                }
            }
            
            statusMessage = "Edit Templates"
        } catch {
            statusMessage = "Edit Templates"
            self.error = error
        }
    }
    func canUpdateTemplate(_ editItem: Template) -> Bool {
        switch action {
        case .status:
            return !templates.allSatisfy { $0.label.status == editItem.label.status }
        case .category:
            guard !editItem.label.category.isEmpty else { return false }
            return !templates.allSatisfy { $0.label.category == editItem.label.category && $0.label.subCategory == editItem.label.subCategory }
        case .rename: //not relevant to EditForm
            return false
        }
    }
    
    
    
    
    func updateCategory(_ editItem:Template) async {
        do {
            statusMessage = "Getting \(editItem.label.category) Folder"
            let destination = try await controller.getDestinationFolder(label:editItem.label, driveID:driveID)

            statusMessage = "Moving Files"
            let moveMods : [(fileID:String, parentID:String, destinationID:String)] =  ids.compactMap { id in
                if let index = controller.index(of: id) {
                    let id       = controller.templates[index].id
                    let parentID       = controller.templates[index].file.parents?.first ?? ""
                    var label    = controller.templates[index].label
                    if label.category != editItem.label.category || label.subCategory != editItem.label.subCategory {
                        label.category    = editItem.label.category
                        label.subCategory = editItem.label.subCategory
                        return (fileID:id, parentID:parentID, destinationID:destination.id)
                    }
                }
                return nil
            }
            let moveResult = try await Drive.shared.move(tuples: moveMods)
            if  moveResult.successes == nil ||  moveResult.successes?.count != moveMods.count{
                print("Failure: \(moveResult.failures?.first?.value.foundationError.localizedDescription ?? "No Failure")")
                throw Template_Error.unableToUpdateCategory
            } else {
                for id in ids {
                    if let index = controller.index(of: id) {
                        controller.templates[index].file.parents    = [destination.id]
                    }
                }
            }
            
            statusMessage = "Updating Labels"
            let labelMods : [(mod:[GTLRDrive_LabelModification], fileID:String)] =  ids.compactMap { id in
                if let index = controller.index(of: id) {
                    let id       = controller.templates[index].id
                    var label    = controller.templates[index].label
                    label.category = editItem.label.category
                    label.subCategory = editItem.label.subCategory
                    return (mod:[label.labelModification], fileID:id)
                }
                return nil
            }
            
            statusMessage = "Updating Drive Labels"
            let labelResult = try await Drive.shared.label(modify: Template.DriveLabel.id.rawValue, modifications: labelMods)
            //Update Local Model
            if  labelResult.successes == nil ||  labelResult.successes?.count != labelMods.count{
                throw Template_Error.unableToUpdateCategory
            }
            for id in ids {
                if let index = controller.index(of: id) {
                    controller.templates[index].label.category    = editItem.label.category
                    controller.templates[index].label.subCategory = editItem.label.subCategory
                }
            }
        
            statusMessage = "Edit Templates"
        } catch {
            statusMessage = "Edit Templates"
            self.error = error
        }
    }
    /*
    var canUpdateStatus : Bool {
        guard templates.filter({ $0.label.status != label.status}).count > 0 else { return false }
        return true
    }
    var canRecategorize : Bool {
        guard !label.category.isEmpty else { return false }
        guard templates.filter({ $0.file.driveId != driveID}).count == 0 else { return false }
        guard templates.filter({ $0.label.category == label.category && $0.label.subCategory == label.subCategory}).count == 0 else { return false}
        return true
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
                    
                    _ =  try await Drive.shared.label(modify: NLF_Form.DriveLabel.id.rawValue, modifications: [controller.forms[index].label.labelModification], on: form.file.id)
                    
                    statusMessage = "Moving \(form.file.title) to \(destination.title) ..."
                    let tempFile = try await Drive.shared.move(file: form.file, to: destination)

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
     */
}
