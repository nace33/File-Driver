//
//  NewContact_Info.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/12/25.
//

import SwiftUI

struct NewContact_Info: View {
    @Environment(ContactDelegate.self) var delegate
    @Bindable var contact: Contact
    @State private var contactInfo = Contact.Info.new(status: .idle)
    @Environment(\.dismiss) var dismiss
    var body: some View {
        EditForm(item: $contactInfo) { info in
            TextField_Suggestions("Category", text: info.category, prompt: nil,   suggestions: suggestions(info.wrappedValue.category))

            TextField_Suggestions("Label", text: info.label, prompt: nil, suggestions: labelSuggestions(info.wrappedValue.category))

            TextField("Value", text:info.value)
            
        } canUpdate: { updateItem in
            guard updateItem.wrappedValue.category.isEmpty == false else { return false }
            guard updateItem.wrappedValue.label.isEmpty == false else { return false }
            guard updateItem.wrappedValue.value.isEmpty == false else { return  false}
            return true
        } update: { updateItem in
            do {
                try await delegate.create(updateItem.wrappedValue)
                dismiss()
            } catch {
                throw error
            }
        }
    }
    func suggestions(_ target:String) -> [String] {
        let existing  = contact.infoCategories
        let hardCoded = Contact.Info.Category.allCases.map(\.title).filter ({ existing.cicContains(string: $0) == false})
        
        return existing + hardCoded
    }
    func labelSuggestions(_ target:String) -> [String] {
        guard let cat = Contact.Info.Category(rawValue: target.wordsToCamelCase()) else {
            return []
        }
        return cat.labels
    }

}


