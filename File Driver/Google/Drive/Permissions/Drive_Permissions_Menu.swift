//
//  Drive_Permissions_Menu.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/2/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce
struct Drive_Permissions_Menu: View {
    let id : String
    let emptyTitle : String
    @Binding var emails : [String]
    
    @State private  var permissions : [GTLRDrive_Permission] = []
    @State private var isLoading : Bool = false
    @State private var error : Error?
    @State private var allPermissions : [GTLRDrive_Permission] = []
    
    var title : String { permissions.isEmpty ? emptyTitle : permissions.compactMap(\.firstName).joined(separator: ", ")}
 
    var imageString : String {
        if permissions.isEmpty {
            return "person.badge.plus"
        }else if permissions.count > 2 {
            return "person.3"
        }else if permissions.count == 2 {
            return "person.2"
        } else {
            return "person"
        }
    }
    var body: some View {
        Menu(title, systemImage:imageString) {
            ForEach(allPermissions, id:\.self) { permission in
                if permissions.contains(permission) {
                    Button("\(permission.name) \(Image(systemName: "checkmark"))") {
                        _ = permissions.remove(id: permission.id)
                    }
                } else {
                    Button(permission.name) {
                        permissions.append(permission)
                    }
                }
            }
        }
            .task(id:id) { await getPermissions() }
            .disabled(isLoading)
    }
    
    func getPermissions() async {
        do {
            isLoading = true
            allPermissions = try await Drive.shared.permissions(fileID:id)
                                                   .filter { $0.emailAddress != nil }
            isLoading = false
            permissions = allPermissions.filter { emails.cicContains(string:$0.emailAddress!)}
        }
        catch {
            isLoading = false
            self.error = error
        }
    }
}

//https://drive.google.com/file/d/1oF_sroSp3aWlmsX2Oe0PRJ4LsoQIAkaQ/edit
#Preview {
    @Previewable @State var emails : [String] = ["jolene@nasserlaw.com"]
    Form {
        Drive_Permissions_Menu(id: "1oF_sroSp3aWlmsX2Oe0PRJ4LsoQIAkaQ", emptyTitle: "Assign To",  emails:$emails)
    }
    .formStyle(.grouped)
    .padding(40)
    
    Divider()
    Drive_Permissions_Menu(id: "1oF_sroSp3aWlmsX2Oe0PRJ4LsoQIAkaQ", emptyTitle: "Hi",  emails:$emails)
        .padding(40)
    
    Divider()
    Drive_Permissions_Menu(id: "1oF_sroSp3aWlmsX2Oe0PRJ4LsoQIAkaQ", emptyTitle: "",  emails:$emails)
        .fixedSize()
        .menuStyle(.borderlessButton)
        .padding(40)
}
