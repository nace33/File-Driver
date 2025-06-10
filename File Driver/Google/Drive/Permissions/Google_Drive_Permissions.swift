//
//  Google_Drive_ShareView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/24/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct Google_Drive_Permissions: View {
    var file :GTLRDrive_File
    fileprivate var itemType : ItemType {
        if file.id == file.driveId { .drive }
        else if file.isFolder { .folder }
        else { .file}
    }
    fileprivate var userEmail : String? {
        Google.shared.user?.profile?.email
    }
    var hasWriteAccess : Bool {
        guard let userEmail = Google.shared.user?.profile?.email,
              let role = permissions.first(where: { $0.emailAddress == userEmail })?.role
            else { return false }
        return role == Role.organizer.rawValue
    }
    
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    @State private var errorText :String?
    @State private var emailAddress : String = ""
    @State private var permissions : [GTLRDrive_Permission] = []
    @State private var role : Role = .reader
    
    var body: some View {
        VStack(alignment:.leading) {
            header
                .padding(.top, 10)
                .padding(.horizontal)
            
            Divider()
            form
                .disabled(isLoading)
                .padding(.horizontal)
                .padding(.vertical)

            Divider()
            footer
                .padding(.horizontal)
                .padding(.bottom, 10)
        }
            .frame(width:400)
            .task(id:file.id) { try? await load() }
    }
}

//MARK: -Functions
extension Google_Drive_Permissions {
    fileprivate func load() async throws {
        do {
            isLoading = true
            role = Role.roles(itemType: itemType).last! //lowest permission level by default
            permissions = try await Google_Drive.shared.permissions(fileID: file.id)
            isLoading = false
        } catch {
            isLoading = false
            errorText = error.localizedDescription
            throw error
        }
    }
    fileprivate func addNewUser() async  {
        guard emailAddress.isValidEmail else { return }
        do {
            isLoading = true
            let permission = GTLRDrive_Permission()
            permission.emailAddress = emailAddress
            permission.role = role.rawValue
            permission.type = "user"
          
            _ = try await Google_Drive.shared.permission(add: permission, fileID: file.id)
            
            emailAddress = ""
            permissions.append(permission)
            try await load()
            isLoading = false
        } catch {
            errorText = error.localizedDescription
            isLoading = false
        }
    }
    fileprivate func remove(_ permission:GTLRDrive_Permission) async {
        guard permissions.count > 1 else { print("Cannot Remove Only User"); return }
        do {
            isLoading = true
            _ = try await Google_Drive.shared.permission(remove:permission, fileID: file.id)
            permissions.removeAll(where: {$0.emailAddress == permission.emailAddress})
            try await load()
            isLoading = false
        } catch {
            isLoading = false
            errorText = error.localizedDescription
        }
    }
    fileprivate func update(_ permission:GTLRDrive_Permission, newRole:Role) async {
        let originalRole = permission.role
        do {
            isLoading = true
            permission.role = newRole.rawValue
            _ = try await Google_Drive.shared.permission(update:permission, fileID: file.id)
            try await load()
            isLoading = false
        } catch {
            permission.role = originalRole
            isLoading = false
            errorText = error.localizedDescription
        }
    }
}


//MARK: -View Builders
extension Google_Drive_Permissions {
    @ViewBuilder var header  : some View {
        HStack {
            Text("Share: \(file.title)")
                .font(.title3).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            if isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 16, height: 16)
            }
        }
    }
    @ViewBuilder var addView : some View {
        HStack {
            TextField("", text: $emailAddress, prompt: Text("Email address"))
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    Task { await addNewUser() }
                }
            
            Menu(role.title(itemType)) {
                ForEach(Role.roles(itemType: itemType), id:\.self) { role in
                    VStack {
                        Button(role.title(itemType)) { self.role = role }
                        if let accessString = role.accessString {
                            Text(accessString).foregroundStyle(.secondary)
                        }
                    }.tag(role)
                }
            }.fixedSize().buttonStyle(.borderless)
        }
    }
    @ViewBuilder var form    : some View {
        Form {
            if let errorText {
                Text(errorText)
                    .foregroundStyle(.orange)
                    .padding(.bottom)
                Button("Try Again") {  self.errorText = nil  }
            } else if hasWriteAccess {
                Section("Add access") {
                    addView
                        .padding(.bottom)
                }
            }
            
            Section("People with access") {
                ForEach(permissions, id:\.self) { permission in
                    formRow(permission)
                }
            }
        }
    }
    @ViewBuilder func formRow(_ permission:GTLRDrive_Permission) -> some View {
        HStack {
            AsyncImage(url: URL(string: permission.photoLink ?? ""), scale: 2.0)
                .frame(width: 32, height: 32)
                .cornerRadius(20)
            VStack(alignment:.leading, spacing:0) {
                HStack {
                    Text(permission.displayName ?? permission.emailAddress ?? "No Name")
                    Spacer()
                    if let userEmail, userEmail == permission.emailAddress {
                        if let roleStr = permission.role, let role = Role(rawValue: roleStr) {
                            Text(role.title(itemType)).foregroundStyle(.secondary)
                        } else {
                            Text("No Role").foregroundStyle(.secondary)
                        }
                    } else if hasWriteAccess,
                              let roleStr = permission.role, let role = Role(rawValue: roleStr) {
                        Menu(role.title(itemType)) {
                            ForEach(Role.roles(itemType: itemType), id:\.self) { role in
                                VStack {
                                    Button(role.title(itemType)) {
                                        Task { await update(permission, newRole: role)}
                                    }
                                    if let accessString = role.accessString {
                                        Text(accessString).foregroundStyle(.secondary)
                                    }
                                }.tag(role)
                            }
                            Divider()
                            Button("Remove Access") { Task { await remove(permission)}}
                                .foregroundStyle(.red)
                        }
                            .fixedSize()
                            .buttonStyle(.borderless)
                            .foregroundStyle(.secondary)
                    } else if let roleStr = permission.role, let role = Role(rawValue: roleStr) {
                        Text(role.title(itemType)).foregroundStyle(.secondary)
                    }
                    else {
                        Text("No Role").foregroundStyle(.secondary)
                    }
                }
                if permission.displayName != nil {
                    Text(permission.emailAddress ?? "No Email")
                        .foregroundStyle(.secondary)
                }
            }
         
        }
    }
    @ViewBuilder var footer  : some View {
        HStack {
            Spacer()
            Button("Done") { dismiss() }
        }
    }
}


//MARK: -Enums
fileprivate enum ItemType : String, CaseIterable { case drive, folder, file }
fileprivate enum Category : String, CaseIterable { case domain, user, group }
fileprivate enum Role : String, CaseIterable, Comparable {
    //owner,     //Not enabled in this app.  Do not want to transfer ownership.
    case organizer //only valid for shared drives
    case fileOrganizer //FileOrganizer role is only allowed on folders.
    case writer  //'Editor' in google UI
    case commenter //used on files, folders
    case reader    //'Viewer" in google UI - used on files
    
    var title : String {
        return switch self {
        case .organizer:
            "Manager"
        case .fileOrganizer:
            "Content Manager"
        case .writer:
            "Editor" //Also called Contributor for sharing Folder or Drive Content
        case .commenter:
            "Commenter"
        case .reader:
            "Viewer"
        }
    }
    func title(_ itemType:ItemType) -> String {
        return switch self {
        case .organizer:
            "Manager"
        case .fileOrganizer:
            "Content Manager"
        case .writer:
            itemType == .file ? "Editor" : "Contributor" //Also called Contributor for sharing Folder or Drive Content
        case .commenter:
            "Commenter"
        case .reader:
            "Viewer"
        }
    }
    var accessString : String? {
        return switch self {
        case .organizer:
            "Manage Content, people and settings"
        case .fileOrganizer:
            "Add, edit, move, delete and share content"
        case .writer:
            "Add or edit files"
        case .commenter:
            nil
        case .reader:
            nil
        }
    }
    static func roles(itemType:ItemType) -> [Role] {
        return switch itemType {
        case .drive:
            [.organizer, .fileOrganizer, .writer, .commenter, .reader]
        case .folder:
            [.fileOrganizer, .writer, .commenter, .reader]
        case .file:
            [.writer, .commenter, .reader]
        }
    }
    var intValue : Int {
        return switch self {
        case .organizer:
            5
        case .fileOrganizer:
            4
        case .writer:
            3
        case .commenter:
            2
        case .reader:
            1
            //            @unknown default:
            //                0
        }
    }
    public static func < (lhs: Role, rhs: Role) -> Bool {
        lhs.intValue < rhs.intValue
    }
}


//MARK: - Preview
#Preview {
    let exampleID = "1v2ONNBqcVsZQkdWA95c751fw65L5Ogt3"
    var file : GTLRDrive_File {
        let f = GTLRDrive_File()
        f.name = "File Driver"
        f.identifier = exampleID
        f.mimeType = "application/vnd.google-apps.folder"
    
        return f
    }
    Google_Drive_Permissions(file:file)
        .frame(minHeight: 600)
        .environment(Google.shared)
}

