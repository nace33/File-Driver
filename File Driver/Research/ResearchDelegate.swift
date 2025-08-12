//
//  ResearchController.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

@Observable final class ResearchDelegate {
    static let shared: ResearchDelegate = { ResearchDelegate() }()
    let title = "Research"
    var items : [Research] = [] {
        didSet {
            loadCategories()
            loadFilterTokens()
        }
    }
    var selectedIDs     : Set<Research.ID> = []
    var scrollToID      : Research.ID?
    var loader          = VLoader_Item(isLoading: true)
    var filter          = Filter()
    var categories     : [String] = []
    var subCategories  : [String] = []
}



//MARK: Load
extension ResearchDelegate {
    func loadItems() async {
        do {
            loader.status = "Loading Research"
            loader.start()
            items = try await Drive.shared.get(filesWithLabelID: Research.DriveLabel.id.rawValue)
                                                     .compactMap { .init(file: $0)}
                                                     .sorted(by: {$0.title.ciCompare($1.title)})
            loader.stop()

        } catch {
            loader.stop(error)
        }
    }
    func loadCategories() {
        let filteredItems = filteredItems.wrappedValue
        categories    = filteredItems.map(\.label.category).unique().sorted(by: <)
        subCategories = filteredItems.filter({!$0.label.subCategory.isEmpty}).map(\.label.subCategory).unique().sorted(by: <)
    }
    func loadFilterTokens() {
        let tokenA = categories.compactMap    { Filter.Token(prefix: .hashTag, title: $0, rawValue: $0)    }
        let tokenB = subCategories.compactMap { Filter.Token(prefix: .dollarSign, title: $0, rawValue: $0) }
        filter.allTokens = tokenA + tokenB
    }
    var filteredItems : Binding<[Research]> {
        Binding {
            let shows :[Research.Show] = UserDefaults.getEnums(forKey: BOF_Settings.Key.researchShow.rawValue)
            let showStatus = shows.compactMap({$0.asStatus })
            return self.items.filter { template in
                guard showStatus.contains(template.label.status) else { return false }
                
                if !self.filter.string.isEmpty, !self.filter.hasTokenPrefix, !template.title.ciContain(self.filter.string) { return false   }
                if !self.filter.tokens.isEmpty {
                    for token in self.filter.tokens {
                        if token.prefix == .hashTag {
                            if template.label.category != token.rawValue { return false }
                        } else if token.prefix == .dollarSign {
                            if template.label.subCategory != token.rawValue { return false }
                        }
                    }
                }
                return true
            }
        } set: { newValue in
            self.items = newValue
        }
    }
}



//MARK: Selection
extension ResearchDelegate {
    var selectedItems     : [Research] {
        items.filter { selectedIDs.contains($0.id)}
    }
    var selectedFiles     : [GTLRDrive_File] {
        selectedItems.map(\.file)
    }
    subscript(id:Research.ID?) -> Research? {
        guard let id, let index = items.firstIndex(where: {$0.id == id}) else { return nil }
        return items[index]
    }
    func checkSelection()  {
        let currentIDs =  filteredItems.wrappedValue.map(\.id)
        let selectionIDs =  Set(selectedIDs)
        if !selectionIDs.isSubset(of: currentIDs) {
            selectedIDs = []
        }
    }

}
