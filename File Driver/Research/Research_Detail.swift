//
//  ResearchDetail.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI

struct Research_Detail: View {
    @Environment(ResearchDelegate.self) var delegate
    @AppStorage("File-Driver.Research_Detail.showLabel") var showLabel = false
    var body: some View {
        Group {
            if delegate.selectedIDs.count > 0 {
                DriveFileView(delegate.selectedFiles)
            } else {
                ContentUnavailableView("No Research Selected", systemImage:Sidebar_Item.Category.research.iconString)
            }
        }
            .frame(minWidth:400, maxWidth: .infinity, maxHeight: .infinity)
    }
}
