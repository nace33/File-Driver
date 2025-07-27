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
    @Environment(\.openURL) var openURL
    
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
        if threadFiles.count > 0 {
            Divider()
            Menu("Email Info") {
                if threadFiles.count == 1 {
                    if let thread = files.first!.gmailThread {
                        emailThread(thread)
                    }
                } else {
                    ForEach(threadFiles) { file in
                        if let thread = file.gmailThread {
                            Menu(file.titleWithoutExtension) {
                                emailThread(thread)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder func emailThread(_ thread:EmailThread) -> some View {
//        Text(thread.mostRecentHeader?.dateInfo?.date ?? Date(), style:.date)
        let subject = thread.subject.removedBlockedWords
        Text(subject.isEmpty ? "No Subject" : subject)
        Divider()
     
        if thread.headers.count == 1 {
            Text(thread.headers[0].dateInfo?.string ?? "No Date Found")
            emailHeader(thread.headers[0])
        } else {
            ForEach(thread.headers) { header in
                Menu(header.dateInfo?.string ?? "No Date Found") {
                    emailHeader(header)
                    let attachments = thread.attachments(for: header, in: thread.headers)
                    if attachments.count > 0 {
                        Divider()
                        Text("Attachments")
                        ForEach(attachments) { attachment in
                            Button(attachment.name ?? "No Attachment Name") { openURL(attachment.url)}
                        }
                    }
                }
            }
        }
 
    }
    @ViewBuilder func emailHeader(_ header:EmailThread.Header) -> some View {
        ForEach(EmailThread.Person.Category.allCases, id:\.self) { category in
            let people = header.people.filter({ $0.category == category})
            if people.count > 0 {
                Divider()
                Text(category.rawValue.firstLetterCamelCapitalized)
                ForEach(people) { person in
                    if person.name.isEmpty {
                        Text(person.email)
                    } else {
                        Text(person.name + " <" + person.email + ">")
                    }
                }
            }
        }
    }
}

fileprivate extension String {
    var removedBlockedWords : String {
        ""
    }
}
