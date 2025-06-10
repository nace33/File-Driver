//
//  Driver_Selector.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive


public
struct Drive_Selector: View {
    var rootTitle : String = "Shared Drives"
    var rootID    : String? = nil
    var mimeTypes : [GTLRDrive_File.MimeType]?
    var canLoad   : ((GTLRDrive_File?) -> Bool)? = nil
    var select    : ((GTLRDrive_File) -> Void)? = nil

    @State private var files : [GTLRDrive_File] = []
    @State private var stack : [GTLRDrive_File] = []
    @State private var selection : Set<GTLRDrive_File> = []
    @State private var selectedFile : GTLRDrive_File?
    @State private var isLoading = false
    let listRowPadding: Double = 5 // This is a guess
    let listRowMinHeight: Double = 45 // This is a guess
    var listRowHeight: Double {
        max(listRowMinHeight, 20 + 2 * listRowPadding)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if isLoading {
                Spacer()
                HStack { Spacer(); ProgressView(); Spacer()}
                Spacer()
            } else {
                List(selection: $selection) {
                    if files.isEmpty { Text("No Files").foregroundStyle(.secondary)}
                    ForEach(files, id: \.self) { file in
                        Label { Text(file.title) } icon: { file.icon }
                    }
                }
                .frame(height: CGFloat(files.count) * CGFloat(self.listRowHeight))
//                .frame(maxHeight: .infinity)
                .background(Color.indigo)

            }
        }
            .task { await load()}
            .onChange(of: stack) { _, _ in Task { await load() } }
            .onChange(of: selection, { oldValue, newValue in
                setSelectedFile(newValue)
            })
            .contextMenu(forSelectionType: GTLRDrive_File.self, menu: { menu($0) }, primaryAction: {  primaryAction($0) })
    }
    
    
  
    @ViewBuilder func menu(_ items:Set<GTLRDrive_File>) -> some View {
        
    }
}
fileprivate extension Drive_Selector {
    func primaryAction(_ items:Set<GTLRDrive_File>) {
        guard let file = items.first else { return }
        if file.isFolder {
            if canLoad?(file) ?? true {
                stack.append(file)
            }
        }else if file.mime == .shortcut, let shortcut = shortCutFile(file) {
            if canLoad?(shortcut) ?? true {
                stack.append(shortcut)
            }
        } else {
//                    action(.double, file)
        }
    }
    func load() async  {
        do {
            isLoading = true
            if let last = stack.last {
                files = try await Google_Drive.shared.getContents(of: last.id, onlyFolders: onlyFolders)
                                                     .filter { validatedMimeTypes?.contains($0.mime) ?? true }
                                                     .sorted { $0.title.ciCompare($1.title)}
                self.selection = [last]
            } else if let rootID, !rootID.isEmpty {
                files = try await Google_Drive.shared.getContents(of:rootID, onlyFolders: onlyFolders)
                                                     .filter { validatedMimeTypes?.contains($0.mime) ?? true }
                                                     .sorted { $0.title.ciCompare($1.title)}
                self.selection = []
                
            } else {
                files = try await Google_Drive.shared.sharedDrivesAsFolders()
                                                     .filter { validatedMimeTypes?.contains($0.mime) ?? true }
                                                     .sorted { $0.title.ciCompare($1.title)}
                self.selection = []
            }
            isLoading = false
        } catch {
            isLoading = false
            print( error.localizedDescription)
        }
    }
}

fileprivate extension Drive_Selector {
    @ViewBuilder var header  : some View {
        HStack {
            pathBar
            if let select {
                Spacer()
                Button("Select") { select(selectedFile!)}
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedFile == nil)
            }
        }
            .lineLimit(1)
            .disabled(isLoading)
            .padding(.vertical,  8)
            .padding(.horizontal, 8)

        Divider()
    }
    @ViewBuilder var pathBar : some View {
        HStack {
            if stack.isNotEmpty {
                Button(rootTitle) { stack.removeAll() }
                Image(systemName: "chevron.right")
            } else {
                Text(rootTitle)
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(stack.enumerated()), id: \.offset) { index, element in
                Button(element.title) {
                    stack.removeSubrange(index+1..<stack.count)
                }
                    .layoutPriority(Double(index))
                if index+1 < stack.count {
                    Image(systemName: "chevron.right")
                }
            }
        }
            .buttonStyle(.plain)
        
    }
}


fileprivate extension Drive_Selector {
    var validatedMimeTypes : [GTLRDrive_File.MimeType]? {
        guard var mimeTypes else { return nil }
        if !mimeTypes.contains(.folder) {
            mimeTypes.append(.folder)
        }
        return mimeTypes
    }

    var onlyFolders : Bool {
        guard let mimeTypes, mimeTypes.count == 1, mimeTypes.first! == .folder else { return false }
        return true
    }
    func shortCutFile(_ original:GTLRDrive_File) -> GTLRDrive_File? {
        guard let targetID = original.shortcutDetails?.targetId  else { return nil }
        let shortCut = GTLRDrive_File()
        shortCut.identifier = targetID
        shortCut.name = original.name
        guard let mimeTypes,
                let ogMimeStr = original.shortcutDetails?.targetMimeType,
                let ogMime = GTLRDrive_File.MimeType(rawValue: ogMimeStr)  else { return shortCut }
        guard mimeTypes.contains(ogMime) else { return nil  }
        return shortCut
    }
    
}

//selected File
public
extension Drive_Selector {
    func setSelectedFile(_ files:Set<GTLRDrive_File>) {
        //mimeTypes must be set
        if let file = files.first == nil ? stack.last : files.first {
            if let mimeTypes {
                selectedFile = mimeTypes.contains(file.mime) ? file : nil
            } else {
                selectedFile = file
            }
        } else {
            selectedFile = nil
        }
    }
}


#Preview {
    Drive_Selector()
        .environment(Google.shared)
        .frame(minHeight: 400)
}

