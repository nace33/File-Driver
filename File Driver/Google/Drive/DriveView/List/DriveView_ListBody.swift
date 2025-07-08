//
//  Google.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/18/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

struct DriveView_ListBody<Row:View>  : View {
    @Environment(DriveDelegate.self) var delegate
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
        switch delegate.sortBy {
        case .ascending, .descending:
            ForEach(files, id:\.self) { file in
                _listRow(file)
            }
                .listRowSeparator(.hidden)
        case .lastModified:
            Date.Section.listSection(items:files, dateKey: \.modifiedTime?.date) { file in
                _listRow(file)
            }
        case .fileType:
            Sections(of: files, groupedBy: \.mime) { header in
                Text(header.title)
            } row: { file in
                _listRow(file).id(file.wrappedValue)
            }
       }
    }
    
    @ViewBuilder func _listRow(_ file: Binding<GTLRDrive_File>) -> some View {
        if let listRow {
            listRow(file)
        }
        else {
            DriveView_Row(file)
        }
    }
}
