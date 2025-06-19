//
//  Google.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/18/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct Google_DriveView_ListBody<Row:View>  : View {
    @Environment(Google_DriveDelegate.self) var delegate
    typealias customListRow = (Binding<GTLRDrive_File>) -> Row
    var listRow  : customListRow?
    
    var files : Binding<[GTLRDrive_File]>

    init(_ files: Binding<[GTLRDrive_File]>, listRow: customListRow?) {
        self.listRow = listRow
        self.files = files
    }
    init(_ files: Binding<[GTLRDrive_File]>) where Row == EmptyView {
        self.listRow = nil
        self.files = files
    }
    
    var body: some View {
        ForEach(files, id:\.self) { file in
            
            if let listRow {
                listRow(file)
            }
            else {
                Google_DriveView_Row(file)
            }
        }
            .listRowSeparator(.hidden)
    }
 
}
