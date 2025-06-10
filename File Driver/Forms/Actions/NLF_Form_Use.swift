//
//  NLF.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/28/25.
//
import SwiftUI

struct NLF_Form_Use : View {
    @Binding var form : NLF_Form
    @Environment(\.dismiss) var dismiss
    @Environment(NFL_FormController.self)  var controller

    
    @State private var isSaving = false
    @State private var isLoading = false
    @State private var error : Error?

    @State private var filename : String = ""
    @State private var saveToCase : Case?
    @State private var cases : [Case] = []
    @State private var caseName : String = ""

    var body: some View {
        VStack(alignment:.leading) {
            Text("Create Copy of Form").font(.title)
            if isSaving { ProgressView("Saving...")}
            else if isLoading { ProgressView("Loading...")}
            else if let error { Text("Error: \(error)") }
            else {
                Form {
                    caseSelector
                    caseSelector2
                    LabeledContent("Folder") {
                        HStack {
                            Text("Work Product")
                            Image(systemName: "chevron.right")
                            Text(form.label.category)
                            Image(systemName: "chevron.right")
                            Text(form.label.subCategory)
                        }
                    }
                    TextField("Filename", text: $filename, axis: .vertical)
                }
                
            }
        }
            .padding()
            .task(id:form.id) { await updateVariables() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Create Form") { Task { await copyTo() }}
                        .disabled(isSaving || saveToCase == nil)
                }
            }
    }
    @State private var selectedCase : Case?
    @ViewBuilder var caseSelector2 : some View {
        Text(caseName.isEmpty ? "Select a case" : caseName)
        
        Picker("Case", selection: $caseName) {
            caseTextField
                .textFieldStyle(.roundedBorder)
            Divider()
            ForEach(cases, id: \.title) { aCase in
                Text(aCase.title).tag(aCase.title)
            }
    
        } currentValueLabel: {
            Text("Select a case")
        }
    }
    @ViewBuilder var caseTextField : some View {
        TextField("Case", text: $caseName)
            .labelsHidden()
            .textInputSuggestions {
                if !caseName.isEmpty {
                    ForEach(cases.filter { $0.title.ciHasPrefix(caseName) && $0.title != caseName}) { caseSuggestion in
                        Text(caseSuggestion.title)
                            .textInputCompletion(caseSuggestion.title)
                    }
                }
            }
            .onChange(of: caseName) { oldValue, newValue in
                if let selected = cases.filter({ $0.title == newValue}).first {
                    saveToCase = selected
                } else {
                    saveToCase = nil
                }
            }
    }
    @ViewBuilder var caseSelector : some View {
        LabeledContent {
        caseTextField
           
            Menu {
                ForEach(cases) { aCase in
                    Button(aCase.title) { caseName = aCase.title}
                }
            } label: {
                EmptyView()
            }
            .fixedSize()
            .menuStyle(.borderlessButton)
        } label: {
            Text("Case")
        }
    }
    
    func copyTo() async {
        
    }

    func updateVariables() async {
        let date = Date()
        self.filename = "\(date.yyyymmdd) " + form.title
        await loadCases()
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
}
