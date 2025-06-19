//
//  Google_DriveView_Header.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/18/25.
//

import SwiftUI



struct Google_DriveView_Header: View {
    let title : String
    @Environment(Google_DriveDelegate.self) var delegate
    var body: some View {
        HStack {
            Google_DriveView_PathBar(title)
            Spacer()
            Google_DriveView_HeaderActions(file: nil, style: .image)
        }
            //minHeight is set because toolbar will get smaller if Select Button was visible, then disappears as delegate.actions change in a view
            .frame(minHeight:22)
            .disabled(delegate.isLoading )
            .buttonStyle(.plain)
            .lineLimit(1)
            .padding(8)
    }
}



