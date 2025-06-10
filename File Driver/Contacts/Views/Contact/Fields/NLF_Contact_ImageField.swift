//
//  NLF.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/4/25.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import BOF_SecretSauce

struct NLF_Contact_ImageField : View {
    @Binding var contact : NLF_Contact
    @Binding var isEditing : Bool
    @State private var isTargeted = false
    @State private var isLoading = false
    @State private var error : Error?
    @State private var imageData : Data?
    @State private var showFileImport = false
    @State private var showPhotoPicker = false
    @Environment(NLF_ContactsController.self) var controller
    @AppStorage(BOF_Settings.Key.contactIconSizeKey.rawValue)   var iconSize : Int = 48
    
    @State private var photosPickerItem: PhotosPickerItem? = nil
    var body: some View {
        ZStack {
            if isLoading {
                Circle()
                    .fill(.clear)
                    .frame(width:48, height:48)
                    .overlay(Circle().stroke((isTargeted || isEditing) ? Color.blue : Color.gray, lineWidth: 2).padding(-2))
                    .padding(8)
                ProgressView()
            }
            else {
                Button { }label: {
                    Image(data:imageData, placeholder: "person")
                        .resizable()
                        .frame(width:48, height:48)
                        .scaledToFit()
                        .clipShape(Circle())
                        .overlay(Circle().stroke((isTargeted || isEditing) ? Color.blue : Color.gray, lineWidth: 2).padding(-2))
                        .padding(8)
           
                }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if !contact.label.iconID.isEmpty {
                            Button("Import from Finder") { showFileImport.toggle() }
                            Button("Import from Photos") { showPhotoPicker.toggle() }
                            Divider()
                            Button("Clear Photo") { Task { await resetImage() } }
                        }
                    }
                    .dropDestination(for: URL.self) { items, location in
                        guard let url = items.first else { return false }
                        Task { await upload( url) }
                        return true
                    } isTargeted: { isTargeted = $0 }
                    .fileImporter(isPresented: $showFileImport, allowedContentTypes: [.image]) { result in
                        switch result {
                        case .success(let success):
                           transferSecurityScoped(success)
                        case .failure(let failure):
                            self.error = failure
                        }
                    }
                    .photosPicker(isPresented: $showPhotoPicker, selection: $photosPickerItem, matching: .images)
                        .onChange(of: photosPickerItem) { oldValue, newValue in
                            transferPhotoPickerItem(newValue)
                        }
            }
        }
            .task(id:contact.id) {
                imageData = nil
                await downloadImage()
            }
    }

    
    
    //Calls
    func downloadImage() async {
        do {
            do {
                imageData = try getCacheImage()
            } catch {
                guard contact.label.iconID.count > 0 else {
                    return
                }
                
                isLoading = true
                let iconFile = try await Google_Drive.shared.download(id: contact.label.iconID)
                try cacheImage(iconFile.data)
                imageData = iconFile.data
                isLoading = false
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            isLoading = false
            self.error = error
        }
    }
    func transferSecurityScoped(_ url:URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else { throw NSError.quick("Unable to get access to the file.") }
            
            let data = try Data(contentsOf:url)
            url.stopAccessingSecurityScopedResource()
            guard let folder = contact.file.parents?.first else { return }
            Task { await upload(data, folder: folder)}
      
        } catch { self.error = error }
    }
    func transferPhotoPickerItem(_ item:PhotosPickerItem?)  {
        guard let item else  { return }
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    guard let folder = contact.file.parents?.first else { return }
                    guard let data else { return }
                    Task {
                        await upload(data, folder:folder)
                    }
                case .failure(let error):
                    self.error = error
                }
            }
        }
    }
    func upload(_ url:URL) async {
        guard let folder = contact.file.parents?.first else { return }
        guard let type = UTType(filenameExtension: url.pathExtension),
              UTType.image.isSupertype(of: type)  else { return }
        do {
            let data = try Data(contentsOf:url)
            await upload(data, folder: folder)
        } catch {
            print("Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    func upload(_ data:Data, folder:String) async {
        do {
            isLoading = true
            #if os(macOS)
            guard let image = NSImage(data: data)?.copy(size: CGSize(width: iconSize, height: iconSize)) else { return }
            #else
            guard let image = UIImage(data: data)?.resized(to: CGSize(width: iconSize, height: iconSize)) else { return }
            #endif
            guard let png = image.PNGRepresentation else { return }
            
            let filename = Date().yyyymmdd + " Contact Icon" + " (\(contact.name))"
            
            let iconFolder   = try await Google_Drive.shared.get(folder: "Profile Icons", parentID: folder, createIfNotFound: true)
            let uploadedFile = try await Google_Drive.shared.upload(data:png, toParentID: iconFolder.id, name: filename, type:UTType.png.identifier)
            
            contact.label.iconID = uploadedFile.id
            _ = try await controller.update(file: contact.file, label: contact.label.labelModification)
            try cacheImage(png)
            imageData = png

            isLoading = false
        } catch {
            print("Error: \(error.localizedDescription)")
            isLoading = false
            self.error = error
        }
    }
    func resetImage() async {
        do {
            isLoading = true
            contact.label.iconID = ""
            _ = try await controller.update(file: contact.file, label: contact.label.labelModification)
            clearCache()
            imageData = nil
            isLoading = false
        } catch {
            print("Error: \(error.localizedDescription)")
            isLoading = false
            self.error = error
        }
    }
}




