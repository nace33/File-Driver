//
//  Forms_List.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/27/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct NLF_Forms_List : View {
    
    @State private var controller = NFL_FormController()

    @State private var showImport = false
    @State private var showNewDoc = false
    @State private var showNewSheet = false
    @State private var editForm : NLF_Form?
    @State private var duplicateForm : NLF_Form?
    
    @AppStorage(BOF_Settings.Key.formsSortKey.rawValue)         var formsSort         : Form_Sort = .category
    @AppStorage(BOF_Settings.Key.formsShowRetiredKey.rawValue)  var formsShowRetired  : Bool      = true
    @AppStorage(BOF_Settings.Key.formsShowDraftingKey.rawValue) var formsShowDrafting : Bool      = true
    @AppStorage(BOF_Settings.Key.formsShowActiveKey.rawValue)   var formsShowActive   : Bool      = true
    
    
  
    var body: some View {
        VStackLoader(title: "", isLoading:$controller.isLoading, status: .constant(""), error: $controller.error) {
            if controller.forms.isEmpty { Text("No Forms Found").foregroundStyle(.secondary)}
            else {
                HSplitView {
                    listView
                        .contextMenu {listMenu  }
                        .frame(minWidth:300, idealWidth: 400, maxWidth: 500)
                    
                    if controller.selection.count == 1, let selected = controller.selectedForms.first {
                        NLF_Form_Inspector(form:selected)
                            .layoutPriority(1)
                    } else if controller.selection.count > 1 {
                        NLF_Form_MultipleSelection(forms:controller.selectedForms)
                            .frame(maxWidth: .infinity, maxHeight:.infinity)
                            .layoutPriority(1)
                    }
                    else {
                        ContentUnavailableView("No Selection", systemImage: "filemenu.and.selection", description: Text("Select a form from the list on the left."))
                            .frame(maxWidth: .infinity, maxHeight:.infinity)
                            .layoutPriority(1)
                    }
                }
            }
        }

        .sheet(isPresented: $showImport)   { NLF_Form_Import()         }
        .sheet(isPresented: $showNewDoc)   { NLF_Form_New(type:.doc)   }
        .sheet(isPresented: $showNewSheet) { NLF_Form_New(type:.sheet) }
        .sheet(item: $editForm) { NLF_Form_Edit(form: $0) }
        .sheet(item:$duplicateForm) { NLF_Form_Duplicate(form:$0) }
        .environment(controller)
        .task { await controller.load() }
        .toolbar {
            ToolbarItem(placement: .navigation) {
               newMenu
            }
        }
    }
}

//MARK: View Builders
fileprivate extension NLF_Forms_List {
    //Toolbar
    @ViewBuilder var newMenu : some View {
        Menu {
            Button("Google Doc")   { showNewDoc.toggle() }
            Button("Google Sheet") { showNewSheet.toggle() }
            Divider()
            Button("Import From Drive")       { showImport.toggle()}
        } label: {
            Text("New")
        }
            .fixedSize()
            .padding(.leading)
    }
    
    //List
    @ViewBuilder var listView : some View {
        VStack(spacing:0) {
            
            let forms = controller.filteredForms
            List(selection:$controller.selection) {
                switch formsSort {
                case .alphabetically:
                    sortedAlphabeticallySection(forms: forms)
                case .category:
                    sortedByCategorySection(forms: forms)
                case .subCategory:
                    sortedBySubCategorySection(forms: forms)
                }
            }
                .alternatingRowBackgrounds()
                .listStyle(.sidebar)
                .searchable(text: $controller.filter.string,
                            tokens: $controller.filter.tokens,
                            placement:.sidebar,
                            prompt: Text("Type to filter, or use # for tags")) { token in
                        Text(token.title)
                }
                .searchSuggestions { controller.filter.searchSuggestions }
      
            
                .contextMenu(forSelectionType: NLF_Form.ID.self, menu: { forms in
                    if forms.count == 1, let formID = forms.first, let formIndex = controller.index(of: formID) {
                        Button("Open in a new tab") { controller.open(controller.forms[formIndex])}
                        Button("Edit metadata") { editForm = controller.forms[formIndex] }
                        Divider()
                        Button("Duplicate") { duplicateForm = controller.forms[formIndex] }
                    }
                }, primaryAction: { forms in
                    if forms.count == 1, let formID = forms.first, let formIndex = controller.index(of: formID) {
                        controller.open(controller.forms[formIndex])
                    }
                })
            
            NLF_Form_Filter(filteredCount: forms.count)
                .padding(.bottom, 8)
        }
    }
    @ViewBuilder func sortedAlphabeticallySection(forms:[NLF_Form]) -> some View {
        ForEach(forms) { form in
            formRow(form)
        }
            .listRowSeparator(.hidden)
    }
    @ViewBuilder func sortedByCategorySection(forms:[NLF_Form])     -> some View {
        let categories = forms.compactMap { $0.label.category }
                              .unique()
                              .sorted(by: { $0.ciCompare($1)})
        ForEach(categories, id:\.self) { category in
            Section(category) {
                let forms = forms.filter { $0.label.category == category }
                ForEach(forms) { form in
                    formRow(form)
                }
            }
        }
            .listRowSeparator(.hidden)
    }
    @ViewBuilder func sortedBySubCategorySection(forms:[NLF_Form])  -> some View {
        let categories = forms.compactMap { $0.label.category }
                              .unique()
                              .sorted(by: { $0.ciCompare($1)})
        
        ForEach(categories, id:\.self) { category in
            Section(category.camelCaseToWords()) {
                let noSubCategories = forms.filter { $0.label.category == category && $0.label.subCategory.isEmpty }
                ForEach(noSubCategories) { form in
                    formRow(form)
                }
                
                let subCategories = forms.filter { $0.label.category == category && !$0.label.subCategory.isEmpty }
                                         .compactMap { $0.label.subCategory }
                                         .unique()

                ForEach(subCategories, id:\.self) { subCategory in
                    Section {
                        let subCatForms = forms.filter { $0.label.category == category && $0.label.subCategory == subCategory }
                        ForEach(subCatForms) { form in
                            formRow(form)
                                .padding(.leading, 20)
                        }
                    } header: {
                        Text(subCategory.camelCaseToWords())
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.secondary)
                            .padding(.leading, 20)
                    }
                }
            }
        }
            .listRowSeparator(.hidden)
    }
    @ViewBuilder func formRow(_ form:NLF_Form)                      -> some View {
        Label {
            Text(form.title)
                .foregroundStyle(form.label.status.color)
                .padding(.leading, 4)
        } icon: {
            form.file.icon
        }
    }
    
    //Menu
    @ViewBuilder var listMenu   : some View {
        NLF_Form_Sort()
        Menu("Show") {
            Toggle("Drafting", isOn: $formsShowDrafting).foregroundStyle(.yellow)
                .padding(.trailing, 8)
            Toggle("Active", isOn: $formsShowActive)
                .padding(.trailing, 8)
            Toggle("Retired", isOn: $formsShowRetired).foregroundStyle(.red)
        }
    }
        
    //Error
    @ViewBuilder func errorView(_ error:Error) -> some View {
        Spacer()
        VStack(alignment:.center) {
            Text("Error: \(error.localizedDescription)")
            Button("Try Again") { Task { await controller.load() }}
        }
        Spacer()
    }
    
    //Loading
    @ViewBuilder func loadingView() -> some View {
        Spacer()
        HStack {
            Spacer()
            ProgressView("Loading Forms ...")
            Spacer()
        }
        Spacer()
    }
}
