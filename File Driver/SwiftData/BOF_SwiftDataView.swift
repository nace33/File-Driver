//
//  BOF_SwiftDataView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/28/25.
//

import SwiftUI
import SwiftData

struct BOF_SwiftDataView: View {
    init(modelType: ModelType) {
        self.modelType = modelType
    }
    @State var modelType: ModelType
    enum ModelType : String, CaseIterable, Codable { case sidebar, filing }
    var body: some View {
        Group {
            switch modelType {
            case .sidebar:
                BOF_SwiftDataView_Sidebar()
            case .filing:
                SD_FilerView()
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
    BOF_SwiftDataView(modelType: .sidebar)
        .modelContainer(swiftData.container)
}

struct BOF_SwiftDataView_Sidebar : View {
    var body: some View {
        Text("Sidebar")
    }
}


