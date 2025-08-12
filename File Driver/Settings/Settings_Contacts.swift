//
//  Settings_Contacts.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/21/25.
//

import SwiftUI

struct Settings_Contacts: View {
    @AppStorage(BOF_Settings.Key.contactsDriveID.rawValue)  var driveID : String = ""
    @AppStorage(BOF_Settings.Key.contactIconSizeKey.rawValue)   var iconSize : Int = 48
    
  
    @AppStorage(BOF_Settings.Key.contactsGroupBy.rawValue)   var groupBy           : Contact.Group = .lastName
    @AppStorage(BOF_Settings.Key.contactsShowImage.rawValue)      var showImage   : Bool = true
    @AppStorage(BOF_Settings.Key.contactsLastNameFirst.rawValue)  var lastNameIsFirst  : Bool = true
    @AppStorage(BOF_Settings.Key.contactsShowColorsKey.rawValue)  var showColors  : Bool = true
    @State private var cacheFailed : Bool = false
    
    var body: some View {
        Form {
            Section {
                TextField("Drive ID", text: $driveID, axis: .vertical)
            }
            
            Section {
                Toggle(isOn: $showImage)  { Text("Profile Image")}
                LabeledContent("Resolution") {
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
                LabeledContent(" ") {
                    VStack(alignment:.trailing) {
                        let url = URL.applicationSupportDirectory.appending(path: "Contacts" , directoryHint: .isDirectory)
                        Button("Reset Profile Images") {
                            cacheFailed = false
                            do {
                                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                            } catch {
                                cacheFailed = true
                            }
                        }
                        .disabled(FileManager.default.fileExists(atPath: url.path()))
                        if cacheFailed {
                            Text("Images already cleared").foregroundStyle(.red)
                        }
                    }
                }
            }
            Section("Contacts List") {
                LabeledContent("Show") {
                    VStack(alignment: .trailing) {
                   
                        Toggle(isOn: $showColors)  { Text("Colors In Name")}
                    }
                }
         
                
                Picker("Group By", selection:$groupBy) {
                    ForEach(Contact.Group.allCases, id:\.self) {group in
                        Text(group.title)
                    }
                }
                Picker("Display", selection:$lastNameIsFirst) {
                    Text("First Name First").tag(false)
                    Text("Last Name First").tag(true)
                }
            }
        
   
        }
            .formStyle(.grouped)
    }
}

#Preview {
    Settings_Contacts()
        .padding()
}
