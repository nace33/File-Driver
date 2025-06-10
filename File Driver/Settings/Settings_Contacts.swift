//
//  Settings_Contacts.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/21/25.
//

import SwiftUI

struct Settings_Contacts: View {
    @AppStorage(BOF_Settings.Key.contactTemplateIDKey.rawValue)  var centralID : String = "1_rQAShOsmeI2XiYY51TSD3G-uhJqKNie4QSGsr9ZAwo"
    @AppStorage(BOF_Settings.Key.contactsDriveIDKey.rawValue)  var driveID : String = ""
    @AppStorage(BOF_Settings.Key.contactIconSizeKey.rawValue)   var iconSize : Int = 48
    
    @AppStorage(BOF_Settings.Key.contactsShowVisibleKey.rawValue) var showVisible : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowHiddenKey.rawValue)  var showHidden  : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowPurgeKey.rawValue)   var showPurge   : Bool = true
    
    var body: some View {
        Form {
            TextField("Contact Template ID", text: $centralID, axis: .vertical)
            TextField("Drive ID", text: $driveID, axis: .vertical)
            
            
 
            LabeledContent("Profile Icon Resolution") {
                VStack {
                    TextField("Profie Size", value: $iconSize, format:.number)
                        .onSubmit {
                            if iconSize < 48 {
                                self.iconSize = 48
                            } else if iconSize > 512 {
                                self.iconSize = 512
                            }
                        }
                        .labelsHidden()
                    HStack {
                        Spacer()
                        Text("Min: 48, Max: 512").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Show Contacts Marked As") {
                Toggle("Visible", isOn: $showVisible)
                Toggle("Hidden", isOn: $showHidden)
                Toggle("Purge", isOn: $showPurge)
            }

        }
            .formStyle(.grouped)
    }
}

#Preview {
    Settings_Contacts()
        .padding()
}
