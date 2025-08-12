//
//  CasesDelegate.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import SwiftUI

import SwiftUI
import GoogleAPIClientForREST_Drive

@Observable
final class CasesDelegate {
    static let shared: CasesDelegate = { CasesDelegate() }()
    let title = "Cases"
    var cases : [Case] = [] {
        didSet {
            loadCategories()
            loadFilterTokens()
        }
    }
    var categories      : [String] = []
    var loader          = VLoader_Item(isLoading: true)
    var filter = Filter()
}


//MARK: - Filter
extension CasesDelegate {
    func loadCases() async {
        do {
            loader.start("Loading Cases")
            cases = try await Case.allCases()
            loader.stop()
        } catch {
            loader.stop(error)
        }
    }
    func loadCategories() {
        categories = cases.map(\.category.title).unique().sorted(by: <)
    }
    func loadFilterTokens() {
        let hashTags    = Case.DriveLabel.Label.Field.Category.allCases.compactMap { Filter.Token(prefix: .hashTag, title: $0.title, rawValue: $0.rawValue)  }
        let dollarSigns = Case.DriveLabel.Label.Field.Status.allCases.compactMap { Filter.Token(prefix: .dollarSign, title: $0.title, rawValue: $0.rawValue)  }
        filter.allTokens = hashTags + dollarSigns
    }
    var filteredCases : Binding<[Case]> {
        Binding {
            let shows :[Case.Show] = UserDefaults.getEnums(forKey: BOF_Settings.Key.casesShow.rawValue)
            let showStatus = shows.compactMap({$0.asStatus })
            return self.cases.filter { aCase in
                guard showStatus.contains(aCase.label.status) else { return false }
                if !self.filter.string.isEmpty, !self.filter.hasTokenPrefix, !aCase.title.ciContain(self.filter.string) { return false   }
                if !self.filter.tokens.isEmpty {
                    for token in self.filter.tokens {
                        if token.prefix == .hashTag {
                            if aCase.category.rawValue   != token.rawValue { return false }
                        }
                        else if token.prefix == .dollarSign {
                            if aCase.status.rawValue != token.rawValue { return false }
                        }
                    }
                }
                return true
            }
 
        } set: { newValue in
            self.cases = newValue
        }
    }
    subscript(id:Case.ID?) -> Case? {
        guard let id, let index = cases.firstIndex(where: {$0.id == id}) else { return nil }
        return cases[index]
    }

}
