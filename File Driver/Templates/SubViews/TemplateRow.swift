//
//  TemplateRow.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/8/25.
//

import SwiftUI

struct TemplateRow: View {
    @Binding var template : Template
    var body: some View {
        Label {
            Text(template.title)
                .foregroundStyle(template.label.status.color)
                .padding(.leading, 4)
        } icon: {
            template.file.icon
        }
    }
}
