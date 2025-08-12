//
//  Case_TrackersView_New.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/5/25.
//

import SwiftUI


struct NewTracker: View {
    @Environment(TrackerDelegate.self) var delegate
    @State private var contacts : [Case.Contact] = []
    @State private var tags     : [Case.Tag] = []
    @State private var status   : Case.Tracker.Status = .waiting
    @State private var comment  : String = ""
    @State private var catString : String = Case.Tracker.Category.evidence.rawValue
    @State private var category  : Case.Tracker.Category = .evidence
    @FocusState private var isFocused

    
    var body: some View {
        EditForm(title: "Create Tracker", prompt: "Create", style: .sheet, item: .constant(Case.Tracker())) { _ in
            FormCustomEnumPicker("Category", selection: $catString, options: Case.Tracker.Category.allCases, customOption: .custom, titleKey: \.title)
            
            Picker("Status", selection: $status) { ForEach(Case.Tracker.Status.allCases, id:\.self) { Text($0.title)}}
                       
            FormTokensPicker(title: "Contacts", items: $contacts, allItems:delegate.aCase.contacts, titleKey: \.name, create:  { createString in
                Case.Contact(name: createString)
            })
            FormTokensPicker(title: "Tags", items: $tags, allItems: delegate.aCase.tags, titleKey: \.name, tokenColor:.green, altColor: .orange) { newTagString in
                Case.Tag(id: UUID().uuidString, name:newTagString, note: nil)
            }
            
            TextField("Comment", text: $comment, prompt: Text("Enter comment here"))

        } canUpdate: { _ in
            true
        } update: { _ in
            let tracker = Case.Tracker(catString: catString, status: status, contactIDs: contacts.map(\.id), tagIDs: tags.map(\.id), fileIDs: [], text: comment)
            try await delegate.newRoot(tracker, contacts: contacts, tags: tags)
        }
    }
}
