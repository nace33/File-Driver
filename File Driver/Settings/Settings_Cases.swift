//
//  Settings_Cases.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import SwiftUI

struct Settings_Cases: View {

    var body: some View {
        Form {
            CasesFilter()
        }
            .formStyle(.grouped)
    }
}

#Preview {
    Settings_Cases()
}
