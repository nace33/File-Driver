//
//  NLF_Form_ExampleList.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/30/25.
//

import SwiftUI


struct NLF_Form_ExampleList : View {
    var form : NLF_Form
    @State private var error: Error?
    @State private var status = "Loading Examples..."
    @State private var isLoading = false
    
    
    var body: some View {
        VStackLoader(title: "", isLoading: $isLoading, status: $status, error: $error) {
            ContentUnavailableView("Under Construction", systemImage: "hammer.circle", description: Text("Ask Jimmy to build this."))
        }
            .task(id:form.id) { await load() }
    }
    
    func load() async {
        do {
            isLoading = true
            try await Task.sleep(for: .seconds(2))
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
        }
    }
}

