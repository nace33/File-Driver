//
//  NLF_Contacts_FileView.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/5/25.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct NLF_Contacts_FileView : View {
    @Binding var contact : NLF_Contact
    @State private var status = ""
    @State private var isLoading = false
    @State private var error : Error?
    
    @State private var showImport : Bool = false
    
    var body: some View {
        Drive_Navigator(rootID: contact.file.parents!.first!, rootname: contact.name) { action, file in
            
        }
    }
}
