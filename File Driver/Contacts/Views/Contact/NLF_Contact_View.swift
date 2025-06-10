//
//  NLF_Contact_View.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/4/25.
//

import SwiftUI
import BOF_SecretSauce



struct NLF_Contact_View: View {
    @Binding var contact : NLF_Contact
    init(_ contact: Binding<NLF_Contact>) {
        _contact = contact
    }
    
    //State
    @State private var error: Error?
    @State private var isActing  = false
    @State private var status    = "Loading..."
    @State private var isEditing = false
    @AppStorage(BOF_Settings.Key.contactSheetKey.rawValue)   var sheet : NLF_Contact.Sheet = .contactInfo

    var body: some View {
        
        
        ScrollView {
            Grid(alignment:.trailing) {
       
                NLF_Contact_View_Header(contact: $contact, isEditing: $isEditing)
                 
                if let error {
                    ErrorView_Center(error) {  Task { await loadContact(sheet)}     }
                }
                else {
                    switch sheet {
                    case .contactInfo:
                        NLF_Contact_Info_View(contact: $contact, isEditing: $isEditing, isLoading: $isActing)
                    case .files:
                        NLF_Contacts_FileView(contact: $contact)
                    case .cases:
                        Text("Cases (Coming Soon)")
                    }       
                }
            }
            .onChange(of: sheet) { _, newSheet in
                Task { await loadContact(newSheet)}
            }
        }
            .task(id:contact.id) { await loadContact(sheet) }
            .background(.background)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Picker("Sheets", selection: $sheet){ ForEach(NLF_Contact.Sheet.allCases, id:\.self) {Text($0.rawValue.camelCaseToWords())}}
                        .pickerStyle(.segmented)
                        .disabled(isActing)
                }
            }
    }

}


//MARK: - Actions
fileprivate
extension NLF_Contact_View {
    func loadContact(_ sheet:NLF_Contact.Sheet) async {
        do {
            isEditing = false
            isActing = true
            status = "Loading \(sheet.rawValue.camelCaseToWords())"
            switch sheet {
            case .contactInfo:
                contact.info = try await Google_Sheets.shared.getValues(spreadsheetID: contact.id, range:sheet.rawValue)
                                                      .compactMap { .init(sheet:sheet, row: $0)}
                contact.sort(sheet)
                contact.infoCategories = contact.info.compactMap { $0.category}.unique().sorted(by: {$0.ciCompare($1)})

            case .files:
                contact.files = try await Google_Sheets.shared.getValues(spreadsheetID: contact.id, range:sheet.rawValue)
                                                      .compactMap { .init(sheet:sheet, row: $0)}
                contact.sort(sheet)
                contact.fileCategories = contact.files.compactMap { $0.category}.unique().sorted(by: {$0.ciCompare($1)})
            case .cases:
                contact.cases = try await Google_Sheets.shared.getValues(spreadsheetID: contact.id, range:sheet.rawValue)
                                                      .compactMap { .init(sheet:sheet, row: $0)}
                contact.sort(sheet)
                contact.caseCategories = contact.cases.compactMap { $0.category}.unique().sorted(by: {$0.ciCompare($1)})
            }
            
            status = ""
            isActing = false
        } catch {
            self.isActing = false
            status = ""
            self.error = error
        }
    }
}

#Preview {
    @Previewable @State var contact = NLF_Contact.new()
    NLF_Contact_View($contact)
        .environment(Google.shared)
}
