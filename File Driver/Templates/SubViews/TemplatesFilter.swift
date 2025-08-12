//
//  TemplatesFilter.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/8/25.
//

import SwiftUI

struct TemplatesFilter: View {
    @Environment(TemplatesDelegate.self) var delegate
    @AppStorage(BOF_Settings.Key.templateGroupBy.rawValue) var groupBy  : Template.Group  = .category
    @AppStorage(BOF_Settings.Key.templatesShow.rawValue)   var show       : [Template.Show] = Template.Show.allCases
    let style : Style
    enum Style { case form, menu }

    var body: some View {
        Group {
            switch style {
            case .form:
                Form {
                    LabeledContent("Show") { listOptionsButtons }
                    listSortPicker
                }
            case .menu:
                LabeledContent("Show") { listOptionsButtons }
                listSortPicker
            }
        }
            .onChange(of: groupBy) { oldValue, newValue in
                delegate.templates.sort(by: { $0[keyPath: groupBy.key] < $1[keyPath: groupBy.key] })
            }
    }


    @ViewBuilder var listOptionsButtons : some View {
        Toggle("Drafting", isOn:Binding(get: {show.contains(.drafting)}, set: { _ in toggle(.drafting) })).foregroundStyle(.yellow)
            .padding(.trailing, 8)
        Toggle("Active",   isOn:Binding(get: {show.contains(.active)}, set: { _ in toggle(.active) }))
            .padding(.trailing, 8)
        Toggle("Retired", isOn:Binding(get: {show.contains(.retired)}, set: { _ in toggle(.retired) }))
            .foregroundStyle(.red)

    }
    @ViewBuilder var listSortPicker : some View {
        Picker("Group By", selection:$groupBy) {
            ForEach(Template.Group.allCases, id:\.self) { sort in
                Text(sort.rawValue.capitalized).tag(sort)
            }
        }
            .fixedSize()
    }
    func toggle(_ showType:Template.Show) {
        if show.contains(showType) {
            show.removeAll(where: {$0 == showType})
        } else {
            show.append(showType)
        }
    }
}

#Preview {
    TemplatesFilter(style: .form)
    TemplatesFilter(style: .menu)
}
