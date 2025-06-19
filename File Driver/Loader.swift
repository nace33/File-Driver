//
//  Loader.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI

struct Loader<Header:View, Content:View>: View {
    let id : String?
    var load:() async throws -> Void
    var header  : () -> Header
    var content : () -> Content
    @State private var isLoading = false
    @State private var error : Error?
    init(id: String?, load: @escaping () async throws -> Void, @ViewBuilder header: @escaping () -> Header, @ViewBuilder  content: @escaping () -> Content) {
        self.id = id
        self.load = load
        self.header = header
        self.content = content
    }
    init(id: String?, load: @escaping () async throws -> Void, @ViewBuilder  content: @escaping () -> Content) where Header == EmptyView {
        self.id = id
        self.load = load
        self.header = {EmptyView()}
        self.content = content
    }
    init(id: String?, load: @escaping () async throws -> Void, @ViewBuilder  header: @escaping () -> Header) where Content == EmptyView {
        self.id = id
        self.load = load
        self.header = header
        self.content = {EmptyView()}
    }
    init(id: String?, load: @escaping () async throws -> Void) where Content == EmptyView, Header == EmptyView {
        self.id = id
        self.load = load
        self.header =  {EmptyView() }
        self.content = {EmptyView() }
    }
    var body: some View {
        VStack(alignment:.leading, spacing:0 ) {
            header()
                .disabled(isLoading)
            if let error {
                errorView(error)
            }else if isLoading {
                loadingView
            } else {
               content()
            }
        }
            .task(id:id) { await internalLoad() }
    }
    func internalLoad() async {
        do {
            isLoading = true
            try await load()
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
        }
    }
}
//MARK: - View Builders
extension Loader {
    @ViewBuilder func errorView(_ error:Error) -> some View {
        Spacer()
        HStack {
            Spacer()
            VStack {
                Text(error.localizedDescription)
                Button("Reload") { Task {
                    await internalLoad()
                }}
            }
            Spacer()
        }
        Spacer()
    }
    @ViewBuilder var loadingView : some View {
        Spacer()
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        Spacer()
    }
}
