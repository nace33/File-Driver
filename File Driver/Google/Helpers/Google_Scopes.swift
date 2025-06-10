//
//  Google_Scopes.swift
//  Cases
//
//  Created by Jimmy Nasser on 8/10/23.
//

import SwiftUI
import GoogleSignIn



//MARK: Scopes
extension Google {
    private  func needToAdd(scopes:[String]) -> [String]? {
        if let grantedScopes = user?.grantedScopes {
            let s = scopes.filter { !grantedScopes.contains($0)}
            return s.isEmpty ? nil : s
        }
        return nil
    }
    private func has(scopes:[String]) -> Bool {
        if !scopes.isEmpty {
            return needToAdd(scopes: scopes) == nil
        }
        return false
    }
    @MainActor
    private func add(scopes:[String]) async -> Bool {
        guard let scopes = needToAdd(scopes: scopes) else { return false }
        guard let user else { return false }
        
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
        let presentingWindow: UIViewController? = UIApplication.shared.connectedScenes
                            .filter({ $0.activationState == .foregroundActive })
                            .compactMap { $0 as? UIWindowScene }
                            .compactMap { $0.keyWindow }
                            .first?.rootViewController
        
#else
        let presentingWindow: NSWindow? = NSApp.windows.first
        
#endif
        
        guard let presentingWindow else { return false }
        return await withCheckedContinuation { continuation in
            user.addScopes(scopes, presenting: presentingWindow) { signInResult, error in
                self.processLoginResult(signInResult, error)
                return continuation.resume(returning: self.has(scopes: scopes))
            }
        }
    }
    static func canProceed(scopes:[String]) async throws -> Bool {
        if !shared.has(scopes: scopes) {
            guard await shared.add(scopes: scopes) else {
                print("Unable to add scopes: \(scopes)")
                throw Google_Error.failedToAddScopes(scopes)
            }
        }
        return true
    }
}

