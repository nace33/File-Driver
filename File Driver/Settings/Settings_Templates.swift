//
//  Settings_Templates.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/17/25.
//

import SwiftUI

struct Settings_Templates: View {
    @AppStorage(BOF_Settings.Key.templateDriveID.rawValue)  var driveID : String = ""
    var body: some View {
        Form {
            Section {
                TextField("Drive ID", text: $driveID, axis: .vertical)
            }
        }
            .formStyle(.grouped)

    }
}

#Preview {
    Settings_Templates()
}
