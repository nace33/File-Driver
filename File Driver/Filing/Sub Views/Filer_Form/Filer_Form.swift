//
//  Filer_Form.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/21/25.
//

import SwiftUI
import BOF_SecretSauce

struct Filer_Form: View {
    @Environment(Filer_Delegate.self) var delegate
    
    var body: some View {
        Form {
            Filer_Filenames()
            Filer_Contacts()
            Filer_Tags()
            Filer_Trackers()
            Filer_Tasks()
        }
            .formStyle(.grouped)
      
    }
}

#Preview {
    Filer_Form()
        .environment(Filer_Delegate())
}
