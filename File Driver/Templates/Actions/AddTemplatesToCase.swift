//
//  AddTemplateToCase.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/8/25.
//

import SwiftUI

struct AddTemplatesToCase: View {
    @Environment(TemplatesDelegate.self) var delegate
    var filerItems : [Filer_Item] {
        delegate.templates
                .filter({delegate.selectedIDs.contains($0.id)})
                .map(\.file)
                .compactMap({Filer_Item(file: $0, action: .copy)})
    }
    var body: some View {
        FilingSheet(showPreview: false, modes: [.cases], items: filerItems, actions: [.newFolder, .cancel]) { state in
//            switch state {
//            case .formPresented(let aCase, let folder):
//                //Could do something fancy here based on category, sub-category
//                print("aCase: \(String(describing: aCase?.title)) Folder: \(String(describing: folder?.title))")
//            default:
//                break
//            }
        }
    }
}

