//
//  DriveView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/17/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive


struct DriveView<H:View, L:View, B:View, R:View>: View {
//    @Environment(DriveDelegate.self) var delegate
    @Binding var delegate : DriveDelegate
    
    //Customize loading and filtering
    typealias canLoadFolder = (GTLRDrive_File) -> Bool
    var canLoad : canLoadFolder? = nil
    typealias externalLoad = () async throws -> [GTLRDrive_File]
    var load : externalLoad? = nil
    
    //Customize toolbar
    typealias customHeader = () -> H
    var header :customHeader? = nil
    
    //Custom List
    typealias customList = () -> L
    var list :customList? = nil
    
    //Custom List Body
    typealias customListBody = (Binding<[GTLRDrive_File]>) -> B
    var listBody :customListBody? = nil
    
    //Custom Row - UI, menus, etc
    typealias customListRow = (Binding<GTLRDrive_File>) -> R
    var listRow :customListRow? = nil
    
    
    //INITS
    init(_ title:String = "Shared Drives", delegate:Binding<DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil)  where H == EmptyView, R == EmptyView, L == EmptyView, B == EmptyView {
        _delegate = delegate
        self.load = load
        self.header = nil
        self.list = nil
        self.listRow = nil
        self.title = title
        self.canLoad = canLoad
    }
    init(_ title:String = "Shared Drives", delegate:Binding<DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil, @ViewBuilder listBody:@escaping customListBody)  where H == EmptyView, R == EmptyView, L == EmptyView {
        _delegate = delegate
        self.load = load
        self.header = nil
        self.list = nil
        self.listRow = nil
        self.listBody = listBody
        self.title = title
        self.canLoad = canLoad
    }
    init(_ title:String = "Shared Drives", delegate:Binding<DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil, @ViewBuilder header: @escaping customHeader) where R == EmptyView, L == EmptyView, B == EmptyView  {
        _delegate = delegate
        self.load = load
        self.header = header
        self.listRow = nil
        self.list = nil
        self.title = title
        self.canLoad = canLoad
    }
    init(_ title:String = "Shared Drives", delegate:Binding<DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil, @ViewBuilder header: @escaping customHeader, @ViewBuilder listBody:@escaping customListBody) where R == EmptyView, L == EmptyView {
        _delegate = delegate
        self.load = load
        self.header = header
        self.listRow = nil
        self.list = nil
        self.listBody = listBody
        self.title = title
        self.canLoad = canLoad
    }
    init(_ title:String = "Shared Drives", delegate:Binding<DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil, @ViewBuilder header: @escaping customHeader, @ViewBuilder list: @escaping customList) where R == EmptyView, B == EmptyView  {
        _delegate = delegate
        self.load = load
        self.header = header
        self.listRow = nil
        self.list = list
        self.title = title
        self.canLoad = canLoad
    }
    init(_ title:String = "Shared Drives", delegate:Binding<DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil, @ViewBuilder list: @escaping customList) where H == EmptyView, R == EmptyView, B == EmptyView  {
        _delegate = delegate
        self.load = load
        self.header = nil
        self.list = list
        self.listRow = nil
        self.title = title
        self.canLoad = canLoad
    }
    init(_ title:String = "Shared Drives", delegate:Binding<DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil, @ViewBuilder listRow:@escaping customListRow) where H == EmptyView, L == EmptyView, B == EmptyView  {
        _delegate = delegate
        self.load = load
        self.list = nil
        self.header = nil
        self.listRow = listRow
        self.title = title
        self.canLoad = canLoad
    }
    init(_ title:String = "Shared Drives", delegate:Binding<DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil, @ViewBuilder header: @escaping customHeader, @ViewBuilder listRow:@escaping customListRow) where L == EmptyView, B == EmptyView {
        _delegate = delegate
        self.load = load
        self.header = header
        self.listRow = listRow
        self.title = title
        self.list = nil
        self.canLoad = canLoad
    }

    let title : String
    @State private var isTargeted = false

    //BODY
    var body: some View {
        VSplitView {
            VStack(alignment:.leading, spacing:0 ) {
                loadHeader()
                if let error = delegate.error {
                    errorView(error)
                }else if delegate.isLoading || delegate.stackWillReloadSoon {
                    loadingView()
                } else {
                   theListView()
                        .contextMenu(forSelectionType: GTLRDrive_File.self, menu: { items in
                            DriveView_ActionMenu(files: items)
                        }, primaryAction: { items in
                            doubleClick(items)
                        })
                }
            }
                .background(.background)
            if delegate.actions.contains(.preview) {
                DriveFileView(delegate.selection.sorted(by: {$0.title.ciCompare($1.title)}))
            }
        }
        
            .sheet(isPresented: Bindable(delegate).showNewFolderSheet) { delegate.newFolderView }
            .sheet(item:Bindable(delegate).renameItem) { delegate.renameView($0)}
            .sheet(item:Bindable(delegate).shareItem)  { delegate.shareView ($0)}
            .sheet(item:Bindable(delegate).deleteItem) { delegate.deleteView($0)}
            .fileExporter(isPresented: Bindable(delegate).showDownloadExport,
                          item: delegate.downloadData,
                          defaultFilename:delegate.downloadFilename) { delegate.processExportResult($0)}
            .if(delegate.actions.contains(.upload)) { content in
                content
                    .importsPDFs(directory:URL.applicationSupportDirectory, filename: "\(Date().yyyymmdd) Scan.pdf", imported: {
                        delegate.upload([$0], to:delegate.stack.last)
                    })
                    .fileImporter(isPresented: Bindable(delegate).showUploadSheet, allowedContentTypes: DriveDelegate.urlTypes, allowsMultipleSelection:true) { result in
                        switch result {
                        case .success(let urls):
                            delegate.upload(urls, to:delegate.uploadToFolder ?? delegate.stack.last)
                        case .failure(let failure):
                            delegate.error = failure
                        }
                    }
                    .dropStyle(isTargeted:$isTargeted)
                    .dropDestination(for: URL.self, action: { urls, _ in
                        delegate.upload(urls, to:delegate.stack.last)
                        return true
                    }, isTargeted: { isT in
                        guard isT else { self.isTargeted = false; return }
                        self.isTargeted = delegate.canUpload(to:delegate.stack.last)
                    })
            }
            .task(id:delegate.stack.last?.id) {
                await delegate.loadStack(load)
            }
            .environment(delegate)
    }
}


//MARK: - Actions
extension DriveView {
    func doubleClick(_ items:Set<GTLRDrive_File>) {
        guard !items.isEmpty else { return }
        if items.count == 1, let clickedItem = items.first  {
            var addToStack = false
            if clickedItem.mime == .folder {
                addToStack = canLoad?(clickedItem) ?? true
            } else if clickedItem.mime == .shortcut,
                      let shortcut = validateShortCutFile(clickedItem) {
                addToStack = canLoad?(shortcut) ?? true
            }
            
            if addToStack {
                delegate.addToStack(clickedItem)
            } else {
                delegate.performActionSelect(clickedItem)
                delegate.doubleClicked = clickedItem
            }
        } else {
            print("Doubled clicked \(items.count) items")
        }

    }
    func validateShortCutFile(_ original:GTLRDrive_File) -> GTLRDrive_File? {
        guard let targetID = original.shortcutDetails?.targetId  else { return nil }
        let shortCut = GTLRDrive_File()
        shortCut.identifier = targetID
        shortCut.name = original.name
        guard let mimeTypes = delegate.mimeTypes,
                let ogMimeStr = original.shortcutDetails?.targetMimeType,
                let ogMime = GTLRDrive_File.MimeType(rawValue: ogMimeStr)  else { return shortCut }
        guard mimeTypes.contains(ogMime) else { return nil  }
        return shortCut
    }
}

//MARK: - View Builders
extension DriveView {
    @ViewBuilder func loadHeader() -> some View {
        if let header {
            header()
        } else {
            DriveView_Header(title:title)
            Divider()
        }
    }
    @ViewBuilder func theListView() -> some View {
        Group {
            if let list { //custom main content, may or may not be a list
                list()
            } else {
               if let listBody {//custom list body
                    DriveView_List(listBody:listBody)
                }
                else if let listRow { //custom list row
                    DriveView_List(listRow:listRow)
                } else {//default list, body and row
                    DriveView_List()
                }
            }
        }
            .frame(maxWidth:.infinity, maxHeight:.infinity)
    }
    @ViewBuilder func errorView(_ error:Error) -> some View {
        Spacer()
        HStack {
            Spacer()
            VStack {
                Text(error.localizedDescription)
                Button("Reload") { Task {
                    delegate.error = nil
                    await delegate.loadStack()
                }}
            }
            Spacer()
        }
        Spacer()
    }
    @ViewBuilder func loadingView() -> some View {
        Spacer()
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        Spacer()
    }
}



//MARK: - Preview
#Preview {
    @Previewable @State var delegate = DriveDelegate(actions:[.select])
    DriveView(delegate: $delegate)
        .environment(Google.shared)
        .frame(minHeight: 400)
}
