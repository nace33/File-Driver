//
//  Google_SignInView.swift
//  Nasser Law Firm
//
//  Created by Jimmy Nasser on 3/10/25.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct Google_SignInView : View {
    @Environment(Google.self) var google


    var body: some View {
        switch google.loginStatus {
        case .readyToSignIn:
            GoogleSignInButton(style: .wide) { google.login() }
        case .signingIn:
            ProgressView("Signing in ...")
        case .signedIn:
            profileView
        case .signedOut:
            GoogleSignInButton(style: .wide) { google.login() }
        case .failed(let error):
            GoogleSignInButton(style: .wide) { google.login() }
            Divider()
            Text("Login Failed: \(error.localizedDescription)").font(.caption).foregroundColor(.red)
        }
    }
    
    @ViewBuilder var profileView : some View {
        HStack {
            
            AsyncImage(url: Google.shared.user?.profile?.imageURL(withDimension: UInt(120))) { image in
                if google.isLoading {
                    ProgressView()
                        .frame(width: 24, height: 24, alignment: .center)
                        .scaleEffect(0.75)
                } else {
                    image.resizable()
                        .clipShape(Circle())
                }
            } placeholder: {
                Image(systemName: "person.circle")
                    .resizable()
            }
            .frame(width: 24, height: 24)

        
            Text(google.user?.profile?.name ?? "No Name").font(.title2).lineLimit(1)
        }

        .contextMenu {
            Button("Sign Out")        { google.logout() }
            Button("Toggle Progress") { google.isLoading.toggle() }
        }
    }
}
