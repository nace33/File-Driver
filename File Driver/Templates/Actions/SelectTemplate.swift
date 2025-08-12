//
//  SelectTemplate.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/7/25.
//

import SwiftUI

struct SelectTemplate: View {
    @Environment(TemplatesDelegate.self) var delegate
   
    let selected : (Template) -> Bool

    var body: some View {
        SelectView(title: "Template", filter: Bindable(delegate).filter.string) {
            TemplatesList(showFilter: false)
        } selected: { templateID in
            if let template = delegate[templateID] {
               return  selected(template)
            }
            return false
        }
            .task { await delegate.loadTemplates() }
    }
}

#Preview {
    SelectTemplate() { selected in
        print("Template: \(selected.title)")
        return false
    }
        .environment(TemplatesDelegate.shared)
}

