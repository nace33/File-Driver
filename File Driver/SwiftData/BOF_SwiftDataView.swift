//
//  BOF_SwiftDataView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/28/25.
//

import SwiftUI
import SwiftData

struct BOF_SwiftDataView: View {
    @State var modelType: ModelType = .suggestions
    enum ModelType : String, CaseIterable { case sidebar, suggestions }
    @Environment(FilingController.self) var controller
    var body: some View {
        Group {
            switch modelType {
            case .sidebar:
                BOF_SwiftDataView_Sidebar()
            case .suggestions:
                BOF_SwiftDataView_Suggestions()
            }
        }
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Picker("Type", selection: $modelType) {
                        ForEach(ModelType.allCases, id: \.self) { type in
                            Text(type.rawValue.firstLetterCapitalized)
                        }
                    }
                }
            }
    }
}

#Preview {
    @Previewable @State var swiftData = BOF_SwiftData.shared
    BOF_SwiftDataView()
        .environment(FilingController.shared)
        .modelContainer(swiftData.container)
}

struct BOF_SwiftDataView_Sidebar : View {
    var body: some View {
        Text("Sidebar")
    }
}


