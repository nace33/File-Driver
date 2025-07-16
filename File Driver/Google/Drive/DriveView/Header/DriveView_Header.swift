//
//  DriveView_Header.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/18/25.
//

import SwiftUI



struct DriveView_Header: View {
    let title : String
    let showActionBar : Bool
    init(title: String, showActionBar: Bool = true) {
        self.title = title
        self.showActionBar = showActionBar
    }
    @Environment(DriveDelegate.self) var delegate
    var body: some View {
        HStack {
            DriveView_PathBar(title)
            Spacer()
            if showActionBar {
                DriveView_ActionBar()
            }
        }
            //minHeight is set because toolbar will get smaller if Select Button was visible, then disappears as delegate.actions change in a view
            .frame(minHeight:22)
            .disabled(delegate.isLoading )
            .buttonStyle(.plain)
            .lineLimit(1)
            .padding(8)
    }
}



