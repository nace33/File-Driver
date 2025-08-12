//
//  Filer_ContactForm.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/9/25.
//

import SwiftUI

struct Filer_ContactForm: View {
    @Environment(Filer_Delegate.self) var delegate
   var body: some View {
        
        Section {
            
            TextField("Category", text:Bindable(delegate).auxString, prompt: Text("Category"))

            TextField("Comment", text:Bindable(delegate).comment, prompt: Text("Enter comment"))
        }
    }
}

#Preview {
    Filer_ContactForm()
}
