//
//  ResearchRow.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/12/25.
//

import SwiftUI

struct ResearchRow: View {
    @Binding var research : Research
    var body: some View {
        Label {
            Text(research.title)
                .foregroundStyle(research.label.status.color)
                .padding(.leading, 4)
        } icon: {
            research.file.icon
        }
    }
}

