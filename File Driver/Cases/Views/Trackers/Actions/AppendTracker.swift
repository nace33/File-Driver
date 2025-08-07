//
//  Case.TrackersView_Update.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/4/25.
//

import SwiftUI


struct AppendTracker: View {
    @Environment(TrackerDelegate.self) var delegate
    @State private var contacts : [Case.Contact] = []
    @State private var tags     : [Case.Tag] = []
    @State private var status   : Case.Tracker.Status = .paused
    @State private var comment  : String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        if let root = delegate.trackerRoots.first(where: {$0.id == delegate.selectedRootID}) {
            EditForm(title: "Update Tracker", prompt: "Update", style: .sheet, item: .constant(Case.Tracker(root: root))) { _ in
                Picker("Status", selection: $status) { ForEach(Case.Tracker.Status.allCases, id:\.self) { Text($0.title)}}
                TextField("Comment", text: $comment, prompt: Text("Enter comment here"))
                FormTokensPicker(title: "Contacts", items: $contacts, allItems: delegate.aCase.contacts, titleKey: \.name, create:  { createString in
                    Case.Contact(name: createString)
                })
                FormTokensPicker(title: "Tags", items: $tags, allItems: delegate.aCase.tags, titleKey: \.name, tokenColor:.green, altColor: .orange) { newTagString in
                    Case.Tag(id: UUID().uuidString, name:newTagString, note: nil)
                }
            } canUpdate: { _ in
              canCreateNewTracker(root)
            } update: { _ in
                try await delegate.append(newTracker(root), in: root, contacts: contacts, tags: tags)
            }
            .onAppear {
                resetVariables(root)
            }
        } else {
            noRootView
        }
    }
    func newTracker(_ root:TrackerRoot) -> Case.Tracker {
        Case.Tracker(id: UUID().uuidString,
                     dateIDString: Date.idString,
                     threadID: root.threadID,
                     contactIDs: contacts.map(\.id),
                     tagIDs: tags.map(\.id),
                     fileIDs: [],
                     text: comment,
                     catString: root.catString,
                     statusString: status.rawValue,
                     createdBy: Google.shared.user?.profile?.email ?? "",
                     isHidden: false,
                     date: Date())
    }
//    func text(_ root:TrackerRoot) -> String {
//        guard isOnlyStatusChange(root) else { return comment}
//        return "Status updated"
//    }
//    func isOnlyStatusChange(_ root:TrackerRoot) -> Bool {
//        contacts.isEmpty && tags.isEmpty && comment.isEmpty && root.status != status
//    }
    func canCreateNewTracker(_ root:TrackerRoot) -> Bool {
        guard contacts.isEmpty, tags.isEmpty, comment.isEmpty else { return true }
        return status != root.status
    }
    func resetVariables(_ root:TrackerRoot) {
        contacts = []
        tags = []
        status = root.status
        comment = ""
    }
    @ViewBuilder var noRootView : some View {
        Form {
            Section {
                Text("Select a Tracker and try again.")
            } footer: {
                Button("Close") { dismiss()  }
            }
           
        }.padding()
            .formStyle(.grouped)
    }

}
