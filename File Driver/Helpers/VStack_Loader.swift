//
//  VStack_Loader.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/29/25.
//

import SwiftUI

@Observable final public class VLoader_Item  {
    fileprivate(set) var isLoading : Bool
    var status    = ""
    var progress : Double = 0.0
    fileprivate(set) var error    : Error?
    private(set) var increment = 0 {
        didSet {
            isLoading = increment != 0
            if !isLoading { progress = 0 }
        }
    }
    init(isLoading:Bool = true) {
        self.isLoading = isLoading
    }
    func forceIsLoading() {
        self.isLoading = true
    }
    func start(_ status:String? = nil) {
        if let status { self.status = status}
        increment += 1
    }
    func stop(_ error:Error? = nil)  {
        increment -= 1
        if let error { self.error = error }
    }
    func clearError() {self.error = nil }
}


public
extension View {
    func VStackLoacker(alignment:HorizontalAlignment = .leading,
                       spacing:CGFloat = 0,
                       title:String = "",
                       loader:Binding<VLoader_Item>,
                       errorAction:(() -> Void)? = nil,
                       @ViewBuilder content: () -> some View,
                       @ViewBuilder footer: () -> some View = {EmptyView()}) -> some View {
        VStackLoader(alignment: alignment, spacing: spacing, isLoading: loader.isLoading, status: loader.status, progress: loader.progress, error: loader.error, errorAction: errorAction) {
            if !title.isEmpty {
                Text(title).font(.title2)
                    .padding()
                Divider()
            }
        } content: {
            content()
        } footer: {
            footer()
        }
    }

    func VStackLoacker(alignment:HorizontalAlignment = .leading,
                       spacing:CGFloat = 0,
                       loader:Binding<VLoader_Item>,
                       errorAction:(() -> Void)? = nil,
                       @ViewBuilder header:  () -> some View,
                       @ViewBuilder content: () -> some View,
                       @ViewBuilder footer: () -> some View = {EmptyView()}) -> some View {
        VStackLoader(alignment: alignment, spacing: spacing, isLoading: loader.isLoading, status: loader.status, progress: loader.progress, error: loader.error, errorAction: errorAction, header: header, content: content, footer:footer)
    }
    
    
    
    func VStackLoader(alignment:HorizontalAlignment = .leading,
                      spacing:CGFloat = 0,
                      title:String = "",
                      isLoading:Binding<Bool>,
                      status:Binding<String>,
                      progress:Binding<Double>? = nil,
                      error:Binding<Error?>,
                      errorAction:(() -> Void)? = nil,
                      @ViewBuilder content: () -> some View,
                      @ViewBuilder footer: () -> some View = { EmptyView()}) -> some View {
        VStackLoader(alignment: alignment, spacing: spacing, isLoading: isLoading, status: status, progress: progress, error: error, errorAction: errorAction) {
            if !title.isEmpty {
                Text(title).font(.title2)
                    .padding()
                Divider()
            }
        } content: {
            content()
        } footer: {
            footer()
        }
    }
    
    func VStackLoader(alignment:HorizontalAlignment = .leading,
                      spacing:CGFloat = 0,
                      isLoading:Binding<Bool>,
                      status:Binding<String>,
                      progress:Binding<Double>? = nil,
                      error:Binding<Error?>,
                      errorAction:(() -> Void)? = nil,
                      @ViewBuilder header:  () -> some View,
                      @ViewBuilder content: () -> some View,
                      @ViewBuilder footer: ()  -> some View = {EmptyView()}) -> some View {
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
                    if let progress, progress.wrappedValue > 0 {
                        ZStack {
                            ProgressView(status.wrappedValue, value: progress.wrappedValue)
                                .progressViewStyle(.circular)
                                .padding()
//                                .tint(progress.wrappedValue == 1 ? .green : .blue)
                                .lineLimit(1)
                        }
                    } else {
                        ProgressView(status.wrappedValue)
                            .padding()
                            .lineLimit(1)
                    }
                    Spacer()
                }
                Spacer()
            }
            else {
                content()
            }
            footer()
        }
    }
}


#Preview {
    let progress = 1.0
    ZStack {
        ZStack {
            ProgressView("Loading", value: progress)
                .progressViewStyle(.circular)
                .padding()
            if progress == 1 {
                Image(systemName: "checkmark")
//                    .resizable()
//                    .frame(width:18, height:18)
                    .padding(.bottom,20)
                    .foregroundStyle(.green)
            }
        }
    }
}
