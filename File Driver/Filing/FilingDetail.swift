//
//  FilingDetail.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive





struct FilingDetail: View {
    @Binding var item : FilingItem
    @State private var destination : GTLRDrive_File?
    @State private var stage : Stage = .selection
    @State private var selectedFolder : GTLRDrive_File?
    @State private var delegate = Google_DriveDelegate(actions: [.filter])
    enum Stage { case selection, filing}
    
    @State private var selectedCase : GTLRDrive_File?
    
 
    var suggestions: [String] {[
        "1a6ZVbhzZt73d3eMIEbwF9mpq40-_2Tsu", "1b8bnuyDt-y_pbYAX3JaZrmB1TQxBWfbu", "1h47DEwUaPUKoSyKxYFVmQsE5K2wYRg1l"
    ]}
    
    var body: some View {
        VStack(alignment: .leading, spacing:0) {
            CaseSelector(suggestions) {
                Button("Add To Case") { }
                    .buttonStyle(.borderedProminent)
            } content: { aCase, folder, stack in
                Form {
                    Text(aCase.title)
                    ForEach(stack) { f in
                        Text(f.title)
                    }
                    Text(folder.title)
                }
            }
        }
    }
}


//MARK: - View Builders
extension FilingDetail {

}



#Preview {
    @Previewable @State var item : FilingItem = .init(file:GTLRDrive_File.sample())
    FilingDetail(item: $item)
        .padding(100)
}

extension GTLRDrive_File {
    static func sample() -> GTLRDrive_File {
        let file = GTLRDrive_File()
        file.name = "Sample File"
        file.mimeType = GTLRDrive_File.MimeType.doc.rawValue
        return file
    }
}
