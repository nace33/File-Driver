//
//  DriveViewActions.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/23/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

struct DriveView_ActionMenu: View {
    let files : Set<GTLRDrive_File>
    @Environment(DriveDelegate.self) var delegate

    var body: some View {
        let actions = delegate.availableActions(for: files)
        
        if actions.count > 0 {
            ForEach(actions, id:\.self) { action in
                Button(action.title) {
                    delegate.perform(action, on: files)
                }
                if action == .newFolder && delegate.selection.count > 1 {
                    Button("New Folder from Selection") {
                        delegate.moveSelectedFilesIntoFolder = true
                        delegate.perform(action, on: files)
                    }
                }
            }
            Divider()
        }
  
        Picker("Sort Files By", selection: Bindable(delegate).sortBy) {
            ForEach(DriveDelegate.SortBy.allCases, id:\.self) { option in
                Button(option.title) { delegate.sortBy = option }
            }
        }
    
        emailMenu
    }
    
    
    //Just FYI - Mostly for testing
    @ViewBuilder var emailMenu : some View {
        let threadFiles = files.filter({ $0.gmailThread != nil}).sorted(by: {$0.title  < $1.title })
        Text("Threads: \(threadFiles.count)")
        if threadFiles.count > 0 {
            Divider()
            Menu("Email Info") {
                ForEach(threadFiles) { file in
                    if let thread = file.gmailThread {
                        Menu(file.titleWithoutExtension) {
                            Text(thread.mostRecentHeader.date, style:.date)
                            Text(thread.intro.subject)
                            ForEach(thread.mostRecentHeader.people.sorted(by: {$0.category.intValue < $1.category.intValue})) { person in
                                Text(person.category.rawValue + " " + person.name + " " + person.email)
                            }
                        }
                    }
                }
            }
        }
    }
}

