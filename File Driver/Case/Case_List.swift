//
//  Case_List.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/22/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct Case_List : View {
    @State private var selected : Case?
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
            } else {
                NavigationStack {
                    List(selection:$selected) {
                        ForEach(cases, id:\.self) { aCase in
                            NavigationLink(aCase.title) {
                                Case_View(aCase: aCase)
                                    .navigationTitle(aCase.title)
                            }
                        }
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
