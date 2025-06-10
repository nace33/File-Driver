//
//  NLF_FormController.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/28/25.
//

import Foundation


@Observable public final
class NFL_FormController {
    var forms           : [NLF_Form] = []
    var categories      : [String] = []
    var subCategories   : [String] = []
    var error           : Error?
    var isLoading       = false
    
    var selection      : Set<NLF_Form.ID> = []
    var filter         = Filter()

}


//MARK: -Load
public
extension NFL_FormController {
    func load() async {
        isLoading = true
        do {
            
            let files = try await Google_Drive.shared.get(filesWithLabelID: NLF_Form.DriveLabel.id.rawValue)
            
            forms = files.compactMap { .init(file: $0)}
                         .sorted(by: {$0.title.ciCompare($1.title)})
            
            categories = forms.compactMap { $0.label.category}
                              .unique()
                              .sorted { $0.ciCompare($1)}
            
            subCategories = forms.compactMap { $0.label.subCategory}
                                 .unique()
                                 .sorted { $0.ciCompare($1)}
       
            loadTokens()
            
            isLoading = false
        }
        catch {
            isLoading = false
            self.error = error
        }
    }
}


//MARK: -Updates
public
extension NFL_FormController {
    func add(_ form: NLF_Form, select:Bool) {
        guard index(of: form) == nil else { return }
        
        forms.append(form)
        
        if !categories.cicContains(string: form.label.category) {
            categories.append(form.label.category)
        }
        
        if !subCategories.cicContains(string:form.label.subCategory) {
            subCategories.append(form.label.subCategory)
        }
        
        if select, let index = index(of: form) {
            selection = [forms[index].id]
        }
    }
    func update(_ editedForm: NLF_Form, select:Bool) {
        guard let index = index(of: editedForm) else {
            return }
        if forms[index].title != editedForm.file.name {
            forms[index].title = editedForm.file.title
            forms.sort(by: {$0.title.ciCompare($1.title)})
        }
        
        if forms[index].label.category != editedForm.label.category {
            forms[index].label.category = editedForm.label.category
        }
        if forms[index].label.subCategory != editedForm.label.subCategory {
            forms[index].label.subCategory = editedForm.label.subCategory
        }
        if forms[index].label.note != editedForm.label.note {
            forms[index].label.note = editedForm.label.note
        }
        if forms[index].label.status != editedForm.label.status {
            forms[index].label.status = editedForm.label.status
        }
        
        if select, let updatedIndex = self.index(of: editedForm) {
            selection = [forms[updatedIndex].id]
        }
    }
}


//MARK: - Get
public extension NFL_FormController {
    func index(of form: NLF_Form) -> Int? {
        forms.firstIndex(where: {form.id == $0.id})
    }
    func index(of formID: NLF_Form.ID) -> Int? {
        forms.firstIndex(where: {formID == $0.id})
    }
    var selectedForms: [NLF_Form] {
        selection.compactMap { id in
            guard let index = index(of: id) else { return nil }
            return forms[index]
        }
            .sorted(by: {$0.title.ciCompare($1.title)})
    }
}


//MARK: -Categories & SubCategories
public
extension NFL_FormController {
    //Categories
    //categories is a variable - defined in load()
    var hardCodedCategories : [String] { NLF_Form.Category.allCases.compactMap { $0.rawValue.camelCaseToWords() } }
    var allCategories : [String] {
        (categories.compactMap({$0.camelCaseToWords()}) + hardCodedCategories)
            .unique() //removes hardCoded that were already loaded
            .sorted { $0.ciCompare($1) }
    }
    func categorySuggestions(withPrefix string:String) -> [String] {
        allCategories
            .filter { $0.ciHasPrefix(string) && $0.lowercased() != string.lowercased() }
    }
    
    //Sub-Categories
    //subCategories is a variable - defined in load()
    var hardCodedSubCategories : [String] { NLF_Form.SubCategory.allCases.compactMap { $0.rawValue.camelCaseToWords() } }
    var allSubCategories : [String] {
        (subCategories.compactMap({$0.camelCaseToWords()}) + hardCodedSubCategories)
            .unique() //removes hardCoded that were already loaded
            .sorted { $0.ciCompare($1) }
    }
    func subCategoriesOfCategory(_ category:String) -> [String] {
        guard !category.isEmpty else { return [] }
   
        
        var subs = forms.filter { $0.label.category == category }
                        .compactMap {$0.label.subCategory.camelCaseToWords() }
                        .unique()
       
        //if category is a hardcoded category, provide hardcoded subcategory suggestions
        if let cat = NLF_Form.Category(string: category) {
            let defSubs = NLF_Form.SubCategory.subCategories(for: cat).compactMap { $0.rawValue.camelCaseToWords() }
            subs += defSubs
        }
        return subs
                    .filter { $0.isEmpty == false}
                    .unique()
                   .sorted { $0.ciCompare($1) }
    }
    func subCategories(withPrefix string:String, in category:String) -> [String] {
        return if category.isEmpty {
            allSubCategories.filter { $0.ciHasPrefix(string) && $0.lowercased() != string.lowercased()}
        } else {
            subCategoriesOfCategory(category).filter { $0.ciHasPrefix(string) && $0.lowercased() != string.lowercased()}
        }
    }
}


//MARK: Open
public
extension NFL_FormController {
    func open(_ form:NLF_Form) {
        File_DriverApp.createWebViewTab(url:form.file.editURL, title: form.title)
    }
}


//MARK: Actions
import GoogleAPIClientForREST_Drive
public extension NFL_FormController {
    func getDestinationFolder(label:NLF_Form.Label, driveID:String) async throws -> GTLRDrive_File {
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
    func create(fileType:GTLRDrive_File.MimeType, filename:String, folder:GTLRDrive_File) async throws -> GTLRDrive_File {
        do {
           return try await Google_Drive.shared.create(fileType:fileType, name: filename, parentID: folder.id)
        }
        catch {
            throw error
        }
    }
    
    func update(file:GTLRDrive_File, label:GTLRDrive_LabelModification) async throws -> GTLRDrive_File {
        
        do {
            //Update label
            _  = try await Google_Drive.shared.label(modify: NLF_Form.DriveLabel.id.rawValue, modifications: [label], on: file.id)
            //fetch file with updated label
           return try await Google_Drive.shared.get(fileID: file.id, labelIDs: [NLF_Form.DriveLabel.id.rawValue])
        }
        catch {
            throw error
        }
    }
    
}



//MARK: -Filter
public
extension NFL_FormController {
    func loadTokens() {
        filter.allTokens  =  allCategories.compactMap    { Filter.Token(prefix: .hashTag,    title: $0.camelCaseToWords(), rawValue: $0)}
        filter.allTokens +=  allSubCategories.compactMap { Filter.Token(prefix: .dollarSign, title: $0.camelCaseToWords(), rawValue: $0)}
    }
    var filteredForms : [NLF_Form] {
        let showRetired      = UserDefaults.standard.bool(forKey: BOF_Settings.Key.formsShowRetiredKey.rawValue)
        let showActive       = UserDefaults.standard.bool(forKey: BOF_Settings.Key.formsShowActiveKey.rawValue)
        let showDrafting     = UserDefaults.standard.bool(forKey: BOF_Settings.Key.formsShowDraftingKey.rawValue)

        return forms.filter { form in
            if !showRetired,  form.label.status == .retired {
                return false
            }
            if !showActive,   form.label.status == .active {
                return false
            }
            if !showDrafting, form.label.status == .drafting {
                return false
            }

            if !filter.string.isEmpty, !filter.hasTokenPrefix, !form.title.ciContain(filter.string) { return false   }
            
            if !filter.tokens.isEmpty {
                for token in filter.tokens {
                    switch token.prefix {
                    case .hashTag:
                        if form.label.category != token.rawValue { return false }
                    case .dollarSign:
                        if form.label.subCategory != token.rawValue { return false }
                    }
                }
            }
        
            return true
        }
    }
}
