//
//  Filing_View.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/22/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce


struct Filing_View: View {
    
    @State private var filter = ""
    @State private var selected : Case?
    @State private var loadingCase : Case?
    @State private var cases : [Case] = []
    @State private var error : Error?
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment:.leading, spacing: 0){
            if let error {
                errorView(error)
            }
            else if isLoading {
                loadingView()
            }
            else if let loadingCase {
                Text("Drive Navigator Here")
//                Drive_Navigator(rootID: loadingCase.parentID,
//                                rootname: loadingCase.title,
//                                onlyFolders: false,
//                                useSystemImage: false,
//                                headerElements: Drive_Navigator.HeaderElement.deluxe,
//                                abilities: Drive_Navigator.Ability.deluxe)  { action, file in
//                    switch action {
//                    case .single, .double:
//                        print("Selected: \(String(describing: file?.title))")
//                    case .pop:
//                        print("pop: \(String(describing: file?.title))")
//                    case .push:
//                        print("push: \(String(describing: file?.title))")
//                    case .rootBack:
//                        print("rootBack: \(String(describing: file?.title))")
//                        if file == nil { self.loadingCase = nil }
//                    }
//                }
            }
            else {
                List(selection:$selected) {
                    ForEach(cases, id:\.self) { aCase in
                        Text(aCase.title)
                    }
                }
                    .contextMenu(forSelectionType: Case.self) { _ in
                        
                    } primaryAction: { selection in
                        if let selected = selection.first {
                            self.loadingCase = selected
                        }
                    }
            }
        }
            .task { await loadCases() }
    }
    
    func loadCases() async {
        print(#function)
        let caseLabelID = Case.DriveLabel.Label.id.rawValue
        isLoading = true
        self.error = nil
        do {
            let caseSpreadsheets = try await Google_Drive.shared.get(filesWithLabelID:caseLabelID)
            cases = caseSpreadsheets.compactMap { Case($0)}
                                    .sorted(by: {$0.title.lowercased() < $1.title.lowercased()})
            isLoading = false
        } catch {
            isLoading = false
            print(#function + " error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    @ViewBuilder func errorView(_ error:Error) -> some View {
        Spacer()
        VStack(alignment:.center) {
            Text("Error: \(error.localizedDescription)")
            Button("Try Again") { Task { await loadCases() }}
        }
        Spacer()
    }
    @ViewBuilder func loadingView() -> some View {
        Spacer()
        HStack {
            Spacer()
            ProgressView("Loading Cases")
            Spacer()
        }
        Spacer()
    }

}

#Preview {
    Filing_View()
        .environment(Google.shared)
}

