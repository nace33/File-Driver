//
//  Filing.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI
import BOF_SecretSauce

struct FilingList: View {
    @Environment(FilingController.self) var controller
    @AppStorage(BOF_Settings.Key.filingDrive.rawValue)        var driveID       : String = ""

    @State private var selectedID   : FilingItem.ID?
    @State private var isTargeted   : Bool        = false
    @State private var isLoading    : Bool        = true
    @State private var showAddSheet : Bool        = false
    @State private var        error : Error?
    var body: some View {
        Group {
            if driveID.isEmpty {
                setDriveIDView
            }
            else if let error {
                errorView(error)
            }
            else if isLoading {
                ProgressView("Loading Filing Drive...")
            }
            else if controller.items.isEmpty {
                nothingToFileView()
            }
            else {
                HSplitView {
                    listView
                        .frame(minWidth:400, idealWidth: 400, maxWidth: 400)
                    Group {
                        if let selectedID = selectedID {
                            if let index = controller.index(of: selectedID) {
                                FilingDetail(item: Bindable(controller).items[index])
                            }else {
                                Button("Ooopsies!") { self.selectedID = nil}.padding(100)
                            }
                        } else {
                            ContentUnavailableView("No Selection", systemImage: "filemenu.and.selection", description: Text("Select a file from the list on the left."))
                        }
                    }
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
//            .fileImporter(isPresented: $showAddSheet, allowedContentTypes: Contact.File.urlTypes) { result in
//                switch result {
//                case .success(let url):
//                    add([url])
//                case .failure(let failure):
//                    self.error = failure
//                }
//            }
//            .dropStyle(isTargeted:$isTargeted)
//            .dropDestination(for: URL.self, action: { urls, _ in
//                add(urls)
//                return true
//            }, isTargeted: {self.isTargeted = $0})
//            .importsPDFs(directory:URL.applicationSupportDirectory, filename: "\(Date().yyyymmdd) Scan.pdf", imported: { add([$0]) })
            .contextMenu {
                Text("File Driver 2.0")
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button { Task { await load() }} label: {Image(systemName: "arrow.clockwise")}
                    Button("Add") { showAddSheet.toggle()}
                }
            }
            .task {
                await load()
            }
    }
    
    func moveToTrash(_ file:FilingItem) async {
        do {
            _ = try await Google_Drive.shared.delete(ids: [file.id])
            if let index = controller.items.firstIndex(where: {$0.id == file.id}) {
                withAnimation {
                   _ =  controller.items.remove(at: index)
                }
            }
        } catch {
            self.error = error
        }
    }
    func load() async {
        do {
            isLoading = true
            try await controller.load()
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
        }
    }
}

//MARK: - Actions
extension FilingList {
    func add(_ urls:[URL]) {
        for url in urls {
            Task {
                _ = url.startAccessingSecurityScopedResource()
                _ = try? await controller.createFilingItem(for: url)
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

}


//MARK: - View Builders
extension FilingList {
    @ViewBuilder var setDriveIDView  : some View {
        Text("Drive Navigator Here")

//        Drive_Selector(rootTitle: "Select Drive To Upload Files to.", rootID: "", mimeTypes: [.folder]) { _ in
//            false
//        } select: { folder in
//            driveID = folder.id
//            Task { await load() }
//        }
    }
    @ViewBuilder func nothingToFileView() -> some View {
        HappyDog("All Filing Is Done!")
    }
    @ViewBuilder func errorView(_ error:Error) -> some View {
        Spacer()
        HStack {
            Spacer()
            VStack {
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                Button("Reload") { Task { await load() }}
            }
            Spacer()
        }
        Spacer()
    }
    @ViewBuilder var listView : some View {
        List(selection: $selectedID) {
            ForEach(Bindable(controller).items) { item in
                    filingRow(item)
                        .contextMenu {
                            Button("Delete") { Task { await moveToTrash(item.wrappedValue) }}
                        }
            }
                .listRowSeparator(.hidden)

        }
    }

    @ViewBuilder func filingRow(_ item: Binding<FilingItem>) -> some View {
        Label {
            Text(item.wrappedValue.name)
                .foregroundStyle(item.wrappedValue.isUploading ? .secondary : .primary)
        } icon: {
            switch item.wrappedValue.status {
            case .uploading:
                let progress = item.wrappedValue.progress
                if progress < 1 {
                    CircularProgressView(progress:Double(progress), color:.blue, font: nil)
                } else {
                    Image(systemName:"checkmark.circle")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.blue)
                }

            case .readyToFile:
                Image(item.wrappedValue.imageString)
                    .resizable()
                    .scaledToFit()

            case .cancelled, .failed:
                Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(item.wrappedValue.status == .cancelled ? .orange : .red)
            }
        }
           .font(.title2)
           .frame(minHeight:20)
           .selectionDisabled(item.wrappedValue.isUploading)
    }
}
