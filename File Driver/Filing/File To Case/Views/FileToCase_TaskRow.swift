//
//  TaskRow.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/3/25.
//
import SwiftUI
import BOF_SecretSauce
import GoogleAPIClientForREST_Drive

struct FileToCase_TaskRow : View {
//    @Environment(Filer_Delegate.self) var delegate
    @Binding var task : Case.Task
    let permissions : [GTLRDrive_Permission]
    var body: some View {
        HStack(alignment:.top) {
            priority
                .frame(minHeight:22)
                .tint(task.priority.color)

            DatePicker_Optional($task.dueDate, in:Date.now...) {
                if task.dueDate == nil {
                    Image(systemName: "calendar.badge.plus")
                }
            }
                .labelsHidden()
                .fixedSize()
                .frame(minHeight:22)
                .foregroundStyle(.blue)

            assign
                .frame(minHeight:22)
                .menuIndicator(.hidden)
                .tint(.blue)
            
            TextField("Text", text: $task.text, prompt: Text("Enter task here"), axis: .vertical)
//                .textFieldStyle(.plain)
                .multilineTextAlignment(.leading)
                .labelsHidden()
                .frame(minHeight:22)
        }
    }

    

    @ViewBuilder var assign : some View {
        Menu {
            if permissions.count > 0 {
                ForEach(permissions) { permission in
                    if let index = task.assigned.firstIndex(where: {$0 == permission.emailAddress}) {
                        Button("\(Image(systemName: "checkmark"))\t\(permission.name)") {
                            task.assigned.remove(at: index)
                        }
                    } else {
                        Button("\(task.assigned.count > 0 ? "\t" : "")" + permission.name) {
                            task.assigned.append(permission.emailAddress ?? "Not Found")
                        }
                    }
                }
                if permissions.count  > 0 {
                    Divider()
                    if task.assigned.count < permissions.count {
                        Button("Select All") {
                            for permission in permissions {
                                if task.assigned.firstIndex(where: {$0 == permission.emailAddress}) == nil {
                                    task.assigned.append(permission.emailAddress ?? "Not Found")
                                }
                            }
                        }
                    } else {
                        Button("Remove All") {
                            for permission in permissions {
                                if let index = task.assigned.firstIndex(where: {$0 == permission.emailAddress}) {
                                    task.assigned.remove(at: index)
                                }
                            }
                        }
                    }
                }
            } else {
                Text("No permissions found.")
            }
        } label: {
            HStack {
                if task.assigned.isEmpty {
                    Image(systemName: "person.badge.plus")
                }
                let names = permissions.filter({ task.assigned.contains($0.emailAddress ?? "Not Found")})
                Text(names.compactMap({$0.firstName}).joined(separator: ", "))
            }
        }
            .fixedSize()
            .menuStyle(.borderlessButton)
            .font(.subheadline)
    }
    @ViewBuilder var priority : some View {
        Menu {
            Text("Task Priority")
            Divider()
            ForEach(Case.Task.Priority.allCases, id:\.self) { priority in
                Button("\(Image(systemName:priority.image))   \(priority.title)") {
                    task.priority = priority
                }
                .foregroundStyle(priority.color)
            }
        } label: {
            Image(systemName: task.priority.image)
        }
            .fixedSize()
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
    }
}
