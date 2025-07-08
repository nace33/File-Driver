
//
//  Settings_Inbox.swift
//  Nasser Law Firm
//
//  Created by Jimmy on 3/30/25.
//

import SwiftUI

struct Settings_Inbox : View {
    @AppStorage(BOF_Settings.Key.inboxImmediateFilingKey.rawValue)  var immediateFiling: Bool = false
    
    
    var body: some View {
        Form {

            Section("Download Emails and Attachments") {
                Toggle("Upload immediately after download", isOn: $immediateFiling)
                LabeledContent("") {
                    if immediateFiling {
                        Text("Selected email/attachments downloaded immediately so uploading to Google Drive can begin.")
                    }
                    else {
                        Text("Links to the email/attachments are saved in 'Filing' so uploading to Google Drive can happen later.")
                    }
                }
                    .multilineTextAlignment(.trailing).font(.caption).foregroundStyle(.secondary)
         
            }
        }.formStyle(.grouped)
    }
}
