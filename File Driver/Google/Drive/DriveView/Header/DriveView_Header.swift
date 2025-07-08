//
//  DriveView_Header.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/18/25.
//

import SwiftUI



struct DriveView_Header: View {
    var title : String = ""
    var showActionBar : Bool = true
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



