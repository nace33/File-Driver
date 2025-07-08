//
//  VStack_Loader.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/29/25.
//

import SwiftUI

public
extension View {
    func VStackLoader(alignment:HorizontalAlignment = .leading,
                      spacing:CGFloat = 0,
                      title:String,
                      isLoading:Binding<Bool>,
                      status:Binding<String>,
                      error:Binding<Error?>,
                      errorAction:(() -> Void)? = nil,
                      @ViewBuilder content: () -> some View) -> some View {
        VStackLoader(alignment: alignment, spacing: spacing, isLoading: isLoading, status: status, error: error, errorAction: errorAction) {
            if !title.isEmpty {
                Text(title).font(.title2)
                    .padding()
                Divider()
            }
        } content: {
            content()
        }
    }
    
    func VStackLoader(alignment:HorizontalAlignment = .leading,
                      spacing:CGFloat = 0,
                      isLoading:Binding<Bool>,
                      status:Binding<String>,
                      error:Binding<Error?>,
                      errorAction:(() -> Void)? = nil,
                      @ViewBuilder header:  () -> some View,
                      @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment:alignment, spacing: spacing) {
            header()
            if let errorString = error.wrappedValue?.localizedDescription {
                Spacer()
                HStack {
                    Spacer()
                    VStack {
                        Label(errorString, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .padding()
                        if let errorAction {
                            Button("Try Again") { errorAction() }
                        }
                    }
                    Spacer()
                }
                Spacer()
            }
            else if isLoading.wrappedValue {
                Spacer()
                HStack {
                    Spacer()
                    ProgressView(status.wrappedValue)
                        .padding()
                    Spacer()
                }
                Spacer()
            }
            else {
                content()
            }
        }
    }
}
