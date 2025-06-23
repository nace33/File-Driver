//
//  Google_DriveView_List.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//


import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

struct Google_DriveView_List<Row:View, B:View>  : View {
    @Environment(Google_DriveDelegate.self) var delegate
    
    typealias customListBody = (Binding<[GTLRDrive_File]>) -> B
    var listBody : customListBody?
    
    typealias customListRow = (Binding<GTLRDrive_File>) -> Row
    var listRow  : customListRow?
 
    init() where Row == EmptyView, B == EmptyView {
        self.listBody = nil
        self.listRow = nil
    }
    init(@ViewBuilder listBody: @escaping customListBody) where Row == EmptyView {
        self.listBody = listBody
        self.listRow = nil
    }
    init(@ViewBuilder listRow: @escaping  customListRow) where B == EmptyView {
        self.listBody = nil
        self.listRow = listRow
    }
    @State private var isTargeted = false
    
    var body: some View {
//        List(selection:Bindable(delegate).selected) {
        List(selection:Bindable(delegate).selection) {
            if !delegate.isLoading, delegate.files.isEmpty {
                Text("Directory is empty.")
                    .foregroundStyle(.secondary)
            } 
            else {
                let files = delegate.filteredBoundFiles
                if let listBody {
                   listBody(files)
               } else {
                   Google_DriveView_ListBody(files, listRow: listRow)
               }
            }
        }
    }
    
    @ViewBuilder func listEmptyView(count:Int) -> some View {
        if !delegate.isLoading, delegate.error == nil,  count == 0 {
            Text("Directory is empty")
                .foregroundStyle(.secondary)
        }
    }
}

