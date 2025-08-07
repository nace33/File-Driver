//
//  Case.TrackersView_Edit.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/5/25.
//

import SwiftUI


struct EditTracker: View {
    @Environment(TrackerDelegate.self) var delegate
    let tracker : Case.Tracker

    @State private var contacts  : [Case.Contact] = []
    @State private var tags      : [Case.Tag]     = []
    @State private var comment   : String = ""
    @State private var catString : String = ""
    @State private var status    : Case.Tracker.Status = .action
    @State private var isHidden  : Bool = false
    
    
    var body: some View {
        EditForm(title: "Edit", prompt: "Save changes", style:.sheet, item: .constant(tracker)) { _ in
                
            FormCustomEnumPicker("Category", selection: $catString, options: Case.Tracker.Category.allCases, customOption: .custom, titleKey: \.title)
            
            Picker("Status", selection: $status) { ForEach(Case.Tracker.Status.allCases, id:\.self) { Text($0.title)}}
                       
            FormTokensPicker(title: "Contacts", items: $contacts, allItems:delegate.aCase.contacts, titleKey: \.name, create:  { createString in
                Case.Contact(name: createString)
            })
            FormTokensPicker(title: "Tags", items: $tags, allItems: delegate.aCase.tags, titleKey: \.name, tokenColor:.green, altColor: .orange) { newTagString in
                Case.Tag(id: UUID().uuidString, name:newTagString, note: nil)
            }
            
            TextField("Comment", text: $comment, prompt: Text("Enter comment here"))
            
            Toggle("Hide Tracker", isOn: $isHidden)
            
        } canUpdate: { _ in
            tracker != updatedTracker
        } update: { _ in
            try await delegate.edit(updatedTracker, contacts: contacts, tags: tags)
        }.task(id:tracker.id) {
            self.contacts   = delegate.aCase.contacts.filter { tracker.contactIDs.contains($0.id)}
            self.tags       = delegate.aCase.tags.filter { tracker.tagIDs.contains($0.id)}
            self.comment    = tracker.text
            self.catString  = tracker.catString
            self.status     = tracker.status
            self.isHidden   = tracker.isHidden
        }
    }
    
    var updatedTracker : Case.Tracker {
        Case.Tracker(id: tracker.id,
                     dateIDString: tracker.dateIDString,
                     threadID: tracker.threadID,
                     contactIDs: contacts.map(\.id),
                     tagIDs: tags.map(\.id),
                     fileIDs: tracker.fileIDs,
                     text: comment,
                     catString: catString,
                     statusString: status.rawValue,
                     createdBy: tracker.createdBy,
                     isHidden: isHidden,
                     date:Date.idDate(tracker.dateIDString)!)
    }
}
