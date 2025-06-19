//
//  Contact_Image2.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/12/25.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct Drive_Imager<T:Drive_Cache>: View {
    let item : T
    let width : CGFloat
    let height : CGFloat
    let placeholder : String
    let showBorder : Bool
    let canEdit : Bool
    let updated : (Data?) -> Void
    
    init(item:T, placeholder:String, width: Double = 48.0, height: Double = 48.0, showBorder:Bool = true, canEdit:Bool = false, updated:@escaping(Data?) -> Void) {
        self.item = item
        self.width = width
        self.height = height
        self.placeholder = placeholder
        self.showBorder = showBorder
        self.updated = updated
        self.canEdit = canEdit
    }

    @State private var cache = Drive_DataCache<T>()
    @State private var error : Error?
    @State private var showFileImport = false
    @State private var showPhotoPicker = false
    @State private var photosPickerItem: PhotosPickerItem? = nil
    @State private var isTargeted = false
    @State private var canRefresh = false
    
    var body: some View {
        Group {
            if canEdit {
                ZStack {
                    imageView
                    Rectangle()
                        .fill(.blue.opacity(0.5))
                        .padding(.top, height - 12)
                    Text("EDIT")
                        .textSelection(.disabled)
                        .padding(.top, height - 12)
                        .font(.system(size: 9))
                        .bold()

                }
                    .contextMenu { menuButtons }
                    .dropDestination(for: URL.self, action: { items, location in
                        guard let url = items.first else { return false }
                        transferFileDropped(url)
                        return true
                    }, isTargeted: {self.isTargeted = $0})
                    .imports(types: [.jpeg], directory: URL.temporaryDirectory, imported: { transferFileDropped($0)  })
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
                    .onHover { isTargeted = $0}
                    .onTapGesture {  showFileImport.toggle()   }

            } else {
                imageView
            }
        }
            .frame(width:width, height:height)
            .scaledToFit()
            .clipShape(Circle())
            .overlay(Circle().stroke(borderColor, lineWidth: 2).padding(-2))
            .task(id: item.cacheID) { load() }
    }
    var borderColor : Color {
        guard showBorder else { return Color.clear }
        return isTargeted ? Color.blue : Color.gray
    }
}


//MARK: - Actions
extension Drive_Imager {
    //load Cache
    func load() {
        canRefresh = false
        cache.item = item
    }
    
    //Extract Data from various importers
    func extracted(_ data:Data) {
        cache.data = data
        updated(data)
        canRefresh = true
    }
    func extractData(_ url:URL) throws {
        do {
            let data = try Data(contentsOf:url)
            extracted(data)
        } catch {
            throw error
        }
    }
    func transferFileDropped(_ url:URL) {
        do {
            try extractData(url)
        } catch {
            self.error = error
        }
    }
    func transferSecurityScoped(_ url:URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                throw NSError.quick("Unable to get access to the file.")
            }
            try extractData(url)
            url.stopAccessingSecurityScopedResource()
        } catch { self.error = error }
    }
    func transferPhotoPickerItem(_ item:PhotosPickerItem?)  {
        guard let item else  { return }
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    guard let data else {
                        self.error = Contact_Error.custom("Image unable to be loaded.")
                        return
                    }
                    extracted(data)
                case .failure(let error):
                    self.error = error
                }
            }
        }
    }
    
    //Clear Cache
    func clearCache() {
        do {
        
            try cache.clearCache()
            if canRefresh {
                refreshCache()
            }
            else {
                updated(nil)
            }
        } catch {
            print("Unable to clear cache \(error.localizedDescription)")
            self.error = error
        }
    }
    
    //referesh
    func refreshCache() {
        canRefresh = false
        cache.refresh()
        updated(nil)
    }
}



//MARK: - View Builders
extension Drive_Imager {
    @ViewBuilder var menuButtons : some View {
        let hasImage = cache.data != nil
        if hasImage && canRefresh {
            Button("Undo") { refreshCache() }
            Divider()
        }
        Button("Import File")  { showFileImport.toggle() }
        Button("Import Photo") { showPhotoPicker.toggle() }
        if hasImage{
            Divider()
            Button("Remove Image")  { clearCache() }
        }
    }
    @ViewBuilder var imageView : some View {
        Image(data:cache.data, placeholder:placeholder)
            .resizable()

    }
}



//MARK: - Preview
#Preview {
    @Previewable @State var contact = Contact.new( firstName: "Frodo", lastName: "Baggins", iconID:"1xQ37nUNiW-n93m3aUxWdD_uiztP_eLx7")
    Drive_Imager<Contact>(item:contact, placeholder: "person", canEdit: false) { updated in
        
    }
    Drive_Imager<Contact>(item:contact, placeholder: "person", canEdit: true) { updated in
        
    }
        .padding(100)
        .environment(Google.shared)
}
