//
//  Contact.Files_View.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import SwiftUI
import BOF_SecretSauce
import GoogleAPIClientForREST_Drive

struct Contact_Files_View: View {
    @Binding var contact : Contact
    @State private var importFile  : ImportFile?
    @State private var previewFile : Contact.File?
    @State private var editFile    : Contact.File?
    @State private var deleteFile  : Contact.File?
    struct ImportFile : Identifiable {
        let id = UUID()
        let category: String
    }
    @Environment(ContactDelegate.self) var delegate
    @State private var error : Error?

    
    var body: some View {
        ForEach(contact.fileCategories, id:\.self) { category in
            categoryGridRow(category)
                .padding(.top, category != contact.infoCategories.first ? 12 : 0)
            
            ForEach(Bindable(contact).files.filter { $0.wrappedValue.category == category}) { file in
                fileGridRow(file)
                    .padding(.bottom, 8)
                    .sheet(item: $editFile, content: { file in
                        if let file = Bindable(contact).files.first(where: {$0.id == file.id}) {
                            EditContact_File(contact:contact, file:file)
                        } else { Button("File not found") { editFile = nil}.padding(40)}
                    })
                    .sheet(item: $previewFile) { PreviewContact_File(file:$0) }
                    .sheet(item: $importFile) {  NewContact_File(contact:contact, category: $0.category)  }
                    .confirmationDialog("Move to Trash?", isPresented:.constant(deleteFile != nil)) {
                        if let file = Bindable(contact).files.first(where: {$0.id == deleteFile?.id}) {
                            Button("Trash", role:.destructive) {
                                delete(file, trash:true)
                                self.deleteFile = nil
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Moves the file to Google Drive Trash.  It can be recovered within 30 days.")
                    }
            }
        }
    }
}


//MARK: - Actions
extension Contact_Files_View {
    func showFileCategoryInDrive(_ category:String) async {
        do {
            #if os(macOS)
            let folder = try await Drive.shared.get(folder: category, parentID: contact.file.parents?.first ?? "")
            File_DriverApp.createWebViewTab(url: folder.showInDriveURL, title: category)
            #endif
        }
        catch {
            self.error = error
        }
    }
    func delete(_ file:Binding<Contact.File>, trash:Bool) {
        Task {
            do {
                try await delegate.delete(file, trash: trash)
            } catch {
                self.error = error
            }
        }
    }
}



//MARK: - View Builders
extension Contact_Files_View {
    @ViewBuilder func categoryGridRow(_ category:String) -> some View {
        GridRow {
            Text(" ")
            HStack {
                Button(category.uppercased()) {
                    importFile = .init(category: category)
                }
                    .buttonStyle(.plain)
                    .bold()
                    .font(.caption)
                    .foregroundStyle(.blue)
                Spacer()
            }
        }
        .contextMenu {
            Button("Show in Google Drive") {  Task { await showFileCategoryInDrive(category) }  }
        }
    }
    @ViewBuilder func fileGridRow(_ file:Binding<Contact.File>) -> some View {
        switch file.wrappedValue.status {
        case .removing, .trashing:
            fileDeletingGridRow(file)
        case .idle:
            GridRow {
                Image(file.wrappedValue.imageString)
                    .resizable()
                    .frame(width:17, height:17)
                    .padding(.trailing, 8)
                    .padding(.leading)
                HStack {
                    Text(file.wrappedValue.filename)
                        .lineLimit(1)
                    Spacer()
                }
                .onTapGesture(count:2) {
                    previewFile = file.wrappedValue
                }
            }
            .contextMenu {
                menu(file)
            }
        }
    }
    @ViewBuilder func fileDeletingGridRow(_ file:Binding<Contact.File>) -> some View {
        GridRow(alignment: .top) {
            Text(file.wrappedValue.status.rawValue.capitalized)
                .padding(.trailing, 8)
                .padding(.leading)
            
            Text_Progress(file.wrappedValue.filename)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(file.wrappedValue.status == .trashing ? .red : .orange)
    }
    @ViewBuilder func menu(_ file:Binding<Contact.File>) -> some View {
        Button("Preview") { previewFile = file.wrappedValue }
        Button("Edit")    { editFile    = file.wrappedValue }
    #if os(macOS)
        Divider()
        Button("Show in Google Drive") {
            File_DriverApp.createWebViewTab(url: GTLRDrive_File.driveURL(id: file.wrappedValue.fileID), title: file.wrappedValue.filename)
        }
        #endif

        Divider()
        Button("Remove from List") { delete(file, trash: false)}
        Button("Move to Trash")    { deleteFile = file.wrappedValue }
    }
}


#Preview {
    @Previewable @State var contact = Contact.new(status: .active, client: .notAClient, firstName: "Frodo", lastName: "Baggins", groupName: "Lord of the Rings", iconID: "", timesUsed: 0)
    Contact_Files_View(contact: $contact)
}
