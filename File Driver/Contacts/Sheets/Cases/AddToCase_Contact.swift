//
//  AddToCase.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/12/25.
//

import SwiftUI
import BOF_SecretSauce

struct AddToCase_Contact: View {
    @Bindable var contact : Contact
    @Environment(\.dismiss) var dismiss
    @State private var error: Error?
    @State private var isLoading = false
    @State private var caseList : [Contact.Case] = []
    @State private var cases : [Case] = []
    @State private var selectedCaseID : Case.ID?
    @State private var filter = ""
    @Environment(ContactsController.self) var controller

    
    var body: some View {
        NavigationStack {
            header
                .padding(.vertical, 10)
                .padding(.horizontal)
            if let error { errorView(error)    }
            else {
                List(selection:$selectedCaseID) {
                    Text("Jimmy - This is incomplete.  Need to finialize Case Spreadsheet")
                        .foregroundStyle(.red)
                    BOFSections(of: filteredCases, groupedBy: \.label.category.title) { cat in
                        Text(cat.uppercased())
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    } row: { aCase in
                        HStack {
                            Text(aCase.title)
                            if isInCase(aCase.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                        .listRowSeparator(.hidden)
                }
                .disabled(isLoading)
           }
        }
            .navigationTitle("Add To Case")
            .frame(minHeight:400)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss()}
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") { Task { await addToSelectedCase() }}
                        .disabled(selectedCaseID == nil || selectedIsInCase)
                        .disabled(isLoading)
                }
            }
            .task(id:contact.id) { await load() }
    }
}



//MARK: - Computed Properties
extension AddToCase_Contact {
    var filteredCases : [Case] {
        cases.filter { aCase in
            guard filter.isEmpty else { return aCase.title.ciHasPrefix(filter)}
            return true
        }
    }
    var selectedIsInCase : Bool {
        guard let selectedCaseID else { return false }
        return isInCase(selectedCaseID)
    }
    var selectedCase : Case? {
        guard let selectedCaseID else { return nil }
        guard let index = cases.firstIndex(where: {$0.id  == selectedCaseID}) else { return nil }
        return cases[index]
    }
}


//MARK: - Action
extension AddToCase_Contact {
    func addToSelectedCase() async {
        do {
            guard let selectedCase else { return }
            guard !isInCase(selectedCase.id) else { return }
            isLoading = true
            try await Task.sleep(for: .seconds(2))
            let aCase : Contact.Case = .init(id:UUID().uuidString,
                                             caseID:selectedCase.id,
                                             driveID:selectedCase.driveID,
                                             category: selectedCase.label.category.title,
                                             name:selectedCase.title)
            //Add to Case Spreadsheet
                        
            //Record in Contact
            try await contact.add(aCase:aCase)
//            isLoading = false
            dismiss()
        } catch {
            isLoading = false
            self.error = error
        }
    }
    func load() async {
        do {
            isLoading = true
            cases = try await Case.allCases()
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
        }
    }
    
    func isInCase(_ aCaseID:Case.ID) -> Bool {
        caseList.firstIndex(where: {$0.caseID == aCaseID}) != nil
    }
}


//MARK: - View Builders
extension AddToCase_Contact {
    @ViewBuilder var header : some View {
        HStack {
            Text("Add to Case")
                .font(.title)
            
            Spacer()
            if isLoading {
                ProgressView()
            } else {
                TextField("Filter", text: $filter, prompt: Text("Filter cases"))
                    .frame(width:150)
                    .fixedSize()
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: filter) { oldValue, newValue in
                        selectedCaseID = nil
                    }
            }
        }
        .frame(minHeight: 32)
    }
    @ViewBuilder func errorView(_ error:Error) -> some View {
        Spacer()
        HStack {
            Spacer()
            Text(error.localizedDescription)
                .foregroundStyle(.red)
            Button("Reload") { Task { await load()}}
            Spacer()
        }
        Spacer()
    }
}
