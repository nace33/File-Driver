//
//  FormsController.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
@Observable
final class TemplatesController {
    static let shared: TemplatesController = { TemplatesController() }()
    let title = "Template"
    var templates : [Template] = [] {
        didSet {
            loadCategories()
            loadFilterTokens()
        }
    }
    var categories     : [String] = []
    var subCategories     : [String] = []
    var selectedIDs: Set<Template.ID> = []
//    var selectedID : Template.ID? = nil
    var scrollToID : Template.ID?
    var isLoading = false
    var loadingError : Error?
    
    var filter = Filter()
}


//MARK: - Load
extension TemplatesController {
    func loadTemplates() async {
        do {
            isLoading = true
            templates = try await Google_Drive.shared.get(filesWithLabelID: Template.DriveLabel.id.rawValue)
                                                     .compactMap { .init(file: $0)}
                                                     .sorted(by: {$0.title.ciCompare($1.title)})
            
            isLoading = false
        } catch {
            isLoading = false
            loadingError = error
        }
    }
    func loadCategories() {
        categories = templates.compactMap { $0.label.category}
                              .unique()
                              .sorted { $0.ciCompare($1)}
        
        subCategories = templates.compactMap { $0.label.subCategory}
                                 .unique()
                                 .sorted { $0.ciCompare($1)}
    }
    func loadFilterTokens() {
        let tokenA = allCategories.compactMap    { Filter.Token(prefix: .hashTag, title: $0, rawValue: $0)  }
        let tokenB = allSubCategories.compactMap { Filter.Token(prefix: .dollarSign, title: $0, rawValue: $0)  }
        filter.allTokens = tokenA + tokenB
    }
}


//MARK: - Create
extension TemplatesController {
    func getDestinationFolder(label:Template.Label, driveID:String) async throws -> GTLRDrive_File {
        do {
            let catFolder = try await Google_Drive.shared.get(folder: label.category, parentID:driveID, createIfNotFound: true)
            
            let destinationFolder : GTLRDrive_File = if !label.subCategory.isEmpty {
                try await Google_Drive.shared.get(folder: label.subCategory, parentID:catFolder.id, createIfNotFound: true)
            } else {
                catFolder
            }
            return destinationFolder
        } catch {
            throw error
        }
    }
    func create(_ template:Template, duplicateFile:String?, progress:(String)->Void) async throws -> Template {
        do {
            guard let driveID = UserDefaults.standard.string(forKey: BOF_Settings.Key.templateDriveID.rawValue) else { throw Template_Error.noDriveID}
            progress("Getting Folder Info...")
            let destinationFolder = try await getDestinationFolder(label: template.label, driveID: driveID)

            let newFile : GTLRDrive_File
            if let duplicateFile {
                progress("Duplicating File")
                newFile = try await Google_Drive.shared.copy(fileID: duplicateFile, rename: template.file.title, saveTo: destinationFolder.id)
            } else {
                progress("Creating Template")
                newFile = try await Google_Drive.shared.create(fileType:template.file.mime, name: template.file.title, parentID: destinationFolder.id)
            }

            progress("Applying Drive Label")
            _  = try await Google_Drive.shared.label(modify: Template.DriveLabel.id.rawValue, modifications: [template.labelModification], on: newFile.id)
          
            progress("Getting Updated File")
            let updatedFile = try await Google_Drive.shared.get(fileID: newFile.id, labelIDs: [Template.DriveLabel.id.rawValue])
            
            //update local data model
            guard let newTemplate = Template(file: updatedFile) else { throw Template_Error.driveLabelMissing(updatedFile.title)}
            progress("Success")

            withAnimation {
                templates.append(newTemplate)
                selectedIDs = [newTemplate.id]
                scrollToID = newTemplate.id
            }
            return template
        } catch {
            progress("Error")
            throw error
        }
    }
}


//MARK: - Update
extension TemplatesController {
    func rename(template:Binding<Template>, newFilename:String, progress:(String)->Void) async throws {
        do {
            progress("Renaming Template")
            _ = try await Google_Drive.shared.rename(id: template.wrappedValue.file.id, newName: newFilename)
            template.wrappedValue.file.name = newFilename
        } catch {
            throw error
        }
    }
    func updateDriveLabel(_ template:Binding<Template>, progress:(String)->Void) async throws {
        do {
            progress("Updating Drive Label")
            let labelModification = template.wrappedValue.labelModification
            let fileID = template.wrappedValue.file.id
            _  = try await Google_Drive.shared.label(modify: Template.DriveLabel.id.rawValue, modifications: [labelModification], on: fileID)
        } catch {
            progress("Error")
            throw error
        }
    }
}



//MARK: - Categories
extension TemplatesController {
    var hardCodedCategories : [String] { Template.Category.allCases.compactMap { $0.rawValue.camelCaseToWords() } }
    var allCategories : [String] {
        (categories.compactMap({$0.camelCaseToWords()}) + hardCodedCategories)
            .unique() //removes hardCoded that were already loaded
            .sorted { $0.ciCompare($1) }
    }
    var hardCodedSubCategories : [String] { Template.SubCategory.allCases.compactMap { $0.rawValue.camelCaseToWords() } }
    var allSubCategories : [String] {
        (subCategories.compactMap({$0.camelCaseToWords()}) + hardCodedSubCategories)
            .unique() //removes hardCoded that were already loaded
            .sorted { $0.ciCompare($1) }
    }
    func subCategoriesOfCategory(_ category:String) -> [String] {
        guard !category.isEmpty else { return [] }
   
        
        var subs = templates.filter { $0.label.category == category }
                        .compactMap {$0.label.subCategory.camelCaseToWords() }
                        .unique()
       
        //if category is a hardcoded category, provide hardcoded subcategory suggestions
        if let cat = Template.Category(string: category) {
            let defSubs = Template.SubCategory.subCategories(for: cat).compactMap { $0.rawValue.camelCaseToWords() }
            subs += defSubs
        }
        return subs
                    .filter { $0.isEmpty == false}
                    .unique()
                    .sorted { $0.ciCompare($1) }
    }
}


//MARK: - Selection
extension TemplatesController {
    func index(of id:Template.ID) -> Int? {
        templates.firstIndex(where: {$0.id == id})
    }
    func index(of template:Template) -> Int? {
        templates.firstIndex(where: {$0.id == template.id})
    }
    subscript(id:Template.ID?) -> Template? {
        guard let id, let index = index(of: id) else { return nil }
        return templates[index]
    }
    var selectedIndex : Int? {
        guard selectedIDs.count == 1,
              let selectedID = selectedIDs.first else { return nil }
        return index(of: selectedID)
    }
    var selected   : Template? {
        guard let selectedIndex else { return nil }
        return templates[selectedIndex]
    }
}
