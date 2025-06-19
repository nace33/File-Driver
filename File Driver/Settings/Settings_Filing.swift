//
//  Settings_Filing.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI

struct Settings_Filing: View {
    @AppStorage(BOF_Settings.Key.filingDrive.rawValue)        var driveID       : String = ""

    var body: some View {
        Form {
            TextField("DriveID", text: $driveID)
        }
    }
}

#Preview {
    Settings_Filing()
}
