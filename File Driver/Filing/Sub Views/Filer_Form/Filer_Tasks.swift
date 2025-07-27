//
//  Filer_Tasks.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/23/25.
//

import SwiftUI

struct Filer_Tasks: View {
    @Environment(Filer_Delegate.self) var delegate
    @State private var newTaskString = ""
    @State private var isCreatingTask = false
    enum Field { case  taskField }
    @FocusState var focusField: Field?
    @State private var error : Error?
    
    var body: some View {
        Section {
            tasksField
            tasksList
        } header: { EmptyView() }
          footer: {  HStack {Spacer(); errorView } }
    }
    
    
    //Actions
    func createTask() async {
        self.error = nil
        guard newTaskString.count > 0 else { return }
        let taskString = newTaskString.trimmingCharacters(in: .whitespaces)
        do {
            newTaskString = ""
            isCreatingTask = true
            if delegate.selectedCase?.permissions.isEmpty ?? false {
                try await delegate.selectedCase?.loadPermissions()
            }
            
//            if Bool.random() {
//                throw NSError.quick("Just checking my pants")
//            }
            let newTask = Case.Task(id: UUID().uuidString, parentID: "", fileIDs: [], contactIDs: [], tagIDs: [], assigned:[], priority:.none, status:.notStarted, isFlagged: false, text: taskString)
            
            withAnimation {
                delegate.tasks.insert(newTask, at: 0)
            }
            isCreatingTask = false
            focusField = .taskField
        } catch {
            newTaskString = taskString
            self.error = error
            isCreatingTask = false
            focusField = .taskField
        }
    }
    func delete(_ task:Case.Task) {
        if let index = delegate.tasks.firstIndex(of: task) {
            withAnimation {
                _ = delegate.tasks.remove(at: index)
            }
        }
    }
    
    
    //View Builders
    @ViewBuilder var errorView     : some View {
        if let error {
            HStack {
                Spacer()
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
                    .onTapGesture {
                        self.error = nil
                    }
            }
        }
    }
    
    ///Tasks
    @ViewBuilder var tasksField    : some View {
        TextField("Tasks", text: $newTaskString, prompt: Text(isCreatingTask ? "Creating..." :  "New Task"))
            .onSubmit { Task { await  createTask() }  }
            .disabled(isCreatingTask)
            .focused($focusField, equals: .taskField)
    }
    @ViewBuilder var tasksList    : some View {
        ForEach(Bindable(delegate).tasks) { task in
            HStack(alignment:.top) {
                Filer_TaskRow(task:task, permissions: delegate.selectedCase?.permissions ?? [])
                Button {delete(task.wrappedValue) } label: {  Image(systemName: "trash") }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                    .frame(minHeight:22)
            }
        }
    }
    

}

import BOF_SecretSauce
import GoogleAPIClientForREST_Drive

struct Filer_TaskRow : View {
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


#Preview {
    Form {
        Filer_Tasks()
    }
        .formStyle(.grouped)
        .environment(Filer_Delegate())
}
