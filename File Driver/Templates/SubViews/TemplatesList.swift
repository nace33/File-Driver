//
//  TemplatesList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/8/25.
//

import SwiftUI
import BOF_SecretSauce

struct TemplatesList: View {
    let showFilter :Bool
    @Environment(TemplatesDelegate.self) var delegate
    @AppStorage(BOF_Settings.Key.templateGroupBy.rawValue)  var groupBy     : Template.Group = .category
    @AppStorage(BOF_Settings.Key.templatesShow.rawValue)    var show     : [Template.Show] = Template.Show.allCases
    
    var body: some View {
        VStack(spacing:0) {
            let filteredTemplates = delegate.filteredTemplates
            ScrollViewReader { proxy in
                List(selection: Bindable(delegate).selectedIDs) {
                    if filteredTemplates.isEmpty {  noFilteredTemplatesView }
                    BOFBoundSections(of: filteredTemplates, groupedBy: groupBy.key, isAlphabetic: groupBy.isAlphabetic) { header in
                        Text(header.isEmpty ? "No Sub-Category" : header)
                    } row: { template in
                        TemplateRow(template:template)
                    }
                        .listRowSeparator(.hidden)
                }
                    .onChange(of: delegate.scrollToID) { _, newID in  proxy.scrollTo(newID)  }
            }
            
            if showFilter {
                Filter_Footer(count:filteredTemplates.count, title:"Templates") {
                    TemplatesFilter(style: .form)
                }
            }
        }
            //this is triggered when 'show' is changed, and casues view to update
            //checkSelection does not need to be called for the sort to occur, the view itself is beign reloaded
            .onChange(of: show) { oldValue, newValue in delegate.checkSelection()}
    }

    
    @ViewBuilder var noFilteredTemplatesView : some View {
        if delegate.templates.count > 0 {
            VStack(alignment:.leading) {
                Text("No Templates Found")
                    .foregroundStyle(.secondary)
                Text("Try changing your filter settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("No Templates")
                .foregroundStyle(.secondary)
        }
    }
}

