//
//  Google_DriveView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/17/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive


struct Google_DriveView<H:View, L:View, B:View, R:View>: View {
//    @Environment(Google_DriveDelegate.self) var delegate
    @Binding var delegate : Google_DriveDelegate
    
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
    init(_ title:String = "Shared Drives", delegate:Binding<Google_DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil)  where H == EmptyView, R == EmptyView, L == EmptyView, B == EmptyView {
        _delegate = delegate
        self.load = load
        self.header = nil
        self.list = nil
        self.listRow = nil
        self.title = title
        self.canLoad = canLoad
    }
    init(_ title:String = "Shared Drives", delegate:Binding<Google_DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil, @ViewBuilder listBody:@escaping customListBody)  where H == EmptyView, R == EmptyView, L == EmptyView {
        _delegate = delegate
        self.load = load
        self.header = nil
        self.list = nil
        self.listRow = nil
        self.listBody = listBody
        self.title = title
        self.canLoad = canLoad
    }
    init(_ title:String = "Shared Drives", delegate:Binding<Google_DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil, @ViewBuilder header: @escaping customHeader) where R == EmptyView, L == EmptyView, B == EmptyView  {
        _delegate = delegate
        self.load = load
        self.header = header
        self.listRow = nil
        self.list = nil
        self.title = title
        self.canLoad = canLoad
    }
    init(_ title:String = "Shared Drives", delegate:Binding<Google_DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil, @ViewBuilder header: @escaping customHeader, @ViewBuilder listBody:@escaping customListBody) where R == EmptyView, L == EmptyView {
        _delegate = delegate
        self.load = load
        self.header = header
        self.listRow = nil
        self.list = nil
        self.listBody = listBody
        self.title = title
        self.canLoad = canLoad
    }
    init(_ title:String = "Shared Drives", delegate:Binding<Google_DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil, @ViewBuilder header: @escaping customHeader, @ViewBuilder list: @escaping customList) where R == EmptyView, B == EmptyView  {
        _delegate = delegate
        self.load = load
        self.header = header
        self.listRow = nil
        self.list = list
        self.title = title
        self.canLoad = canLoad
    }
    init(_ title:String = "Shared Drives", delegate:Binding<Google_DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil, @ViewBuilder list: @escaping customList) where H == EmptyView, R == EmptyView, B == EmptyView  {
        _delegate = delegate
        self.load = load
        self.header = nil
        self.list = list
        self.listRow = nil
        self.title = title
        self.canLoad = canLoad
    }
    init(_ title:String = "Shared Drives", delegate:Binding<Google_DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil, @ViewBuilder listRow:@escaping customListRow) where H == EmptyView, L == EmptyView, B == EmptyView  {
        _delegate = delegate
        self.load = load
        self.list = nil
        self.header = nil
        self.listRow = listRow
        self.title = title
        self.canLoad = canLoad
    }
    init(_ title:String = "Shared Drives", delegate:Binding<Google_DriveDelegate>, canLoad : canLoadFolder? = nil, load: externalLoad? = nil, @ViewBuilder header: @escaping customHeader, @ViewBuilder listRow:@escaping customListRow) where L == EmptyView, B == EmptyView {
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
        VStack(alignment:.leading, spacing:0 ) {
            loadHeader()
            if let error = delegate.error {
                errorView(error)
            }else if delegate.isLoading {
                loadingView()
            } else {
               theListView()
                    .contextMenu(forSelectionType: GTLRDrive_File.self, menu: { items in
                        if items.isEmpty {
                            Google_DriveView_HeaderActionButtons(file:nil, style:.text)
                        }
                    }, primaryAction: { items in
                        doubleClick(items)
                    })
            }
        }
            .background(.background)
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
                    .fileImporter(isPresented: Bindable(delegate).showUploadSheet, allowedContentTypes: Contact.File.urlTypes) { result in
                        switch result {
                        case .success(let url):
                            delegate.upload([url], to:delegate.uploadToFolder)
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
extension Google_DriveView {
    func doubleClick(_ items:Set<GTLRDrive_File>) {
        guard !items.isEmpty else { return }
        let clickedItem = items.first!
        if clickedItem.mime == .folder {
            if canLoad?(clickedItem) ?? true {
                delegate.addToStack(clickedItem)
            }
        } else if clickedItem.mime == .shortcut,
                    let shortcut = validateShortCutFile(clickedItem) {
            if canLoad?(shortcut) ?? true {
                delegate.addToStack(clickedItem)
            }
        }
        else {
            if delegate.actions.contains(.select) {
                delegate.selectItem = clickedItem
            }
            delegate.doubleClicked = clickedItem
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
extension Google_DriveView {
    @ViewBuilder func loadHeader() -> some View {
        if let header {
            header()
        } else {
            Google_DriveView_Header(title:title)
            Divider()
        }
    }
    @ViewBuilder func theListView() -> some View {
        Group {
            if let list { //custom main content, may or may not be a list
                list()
            } else {
               if let listBody {//custom list body
                    Google_DriveView_List(listBody:listBody)
                }
                else if let listRow { //custom list row
                    Google_DriveView_List(listRow:listRow)
                } else {//default list, body and row
                    Google_DriveView_List()
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
    @Previewable @State var delegate = Google_DriveDelegate(actions:[.select])
    Google_DriveView(delegate: $delegate)
        .environment(Google.shared)
        .frame(minHeight: 400)
}
