//
//  Settings_Cases.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import SwiftUI

struct Settings_Cases: View {
    @AppStorage(BOF_Settings.Key.caseTemplateID.rawValue) var templateID  = ""

    var body: some View {
        Form {
            TextField("Case Template ID", text: $templateID)
        }
        .formStyle(.grouped)

    }
}

#Preview {
    Settings_Cases()
}
