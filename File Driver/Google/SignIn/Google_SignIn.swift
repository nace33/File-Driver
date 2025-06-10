//

import Foundation
import GoogleSignIn
import SwiftUI

//MARK: SignInStatus Enum
extension Google {
    enum SignInStatus : Equatable, Comparable {
        static func < (lhs: SignInStatus, rhs: SignInStatus) -> Bool {
            lhs.intValue < rhs.intValue
        }
        static func == (lhs: SignInStatus, rhs: SignInStatus) -> Bool {
            lhs.intValue == rhs.intValue
        }
        case  signedOut, failed(Error), readyToSignIn, signingIn, signedIn
        var intValue : Int {
            return switch self {
            case .signedOut:
                0
            case .failed(_):
                1
            case .readyToSignIn:
                2
            case .signingIn:
                3
            case .signedIn:
                4
            }
        }
    }
}



//MARK: SignIn Logic
extension Google {
    func login() {
        loginStatus = .signingIn
        user = nil
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
        let rvc: UIViewController? = UIApplication.shared.connectedScenes
                                                        .filter({ $0.activationState == .foregroundActive })
                                                        .compactMap { $0 as? UIWindowScene }
                                                        .compactMap { $0.keyWindow }
                                                        .first?.rootViewController
        guard let rvc else {
            print("No Root View Controller")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rvc) { signInResult, error in
            self.processLoginResult(signInResult, error)
        }
#else
        guard let window = NSApplication.shared.windows.first else {
                print("No Root View Controller")
                return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: window) { signInResult, error in
            self.processLoginResult(signInResult, error)
        }
#endif
    }
    func logout() {
        GIDSignIn.sharedInstance.signOut()
        loginStatus = .signedOut
        user = nil
    }
    func restoreLogin() {
        loginStatus = .signingIn
        user = nil
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                self.processUserLogin(user, error)
            }
        } else {
            loginStatus = .readyToSignIn
        }
    }
    func processLoginResult(_ signInResult:GIDSignInResult?,_ error:Error?) {
        guard let result = signInResult else {
            if let error {
                loginStatus = .failed(error)
            } else {
                loginStatus = .failed(Google_Error.loginError("Unknown Reason 1"))
            }
            return
        }
        processUserLogin(result.user, error)
    }
    func processUserLogin(_ user:GIDGoogleUser?, _ error:Error?) {
        guard let user else {
            if let error {
                loginStatus = .failed(error)
            } else {
                loginStatus = .failed(Google_Error.loginError("Unknown Reason 2"))
            }
            return
        }
        self.user = user
        loginStatus = .signedIn
    }

}


