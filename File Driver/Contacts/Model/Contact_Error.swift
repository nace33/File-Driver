//
//  Contact.Error.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/10/25.
//

import SwiftUI

//MARK: -Error
enum Contact_Error : LocalizedError {
    
    case noDrive
    case noTemplate
    case invalidMethodParameters(String)
    case localIssueAskJimmyAbout(String)
    case contactNotFound(String)
    case custom(String)
    var localizedDescription: String {
        switch self {
        case .noDrive:
            "No Drive"
        case .noTemplate:
            "No Template"
        case .invalidMethodParameters(let function):
            "Invalid method parameters: \(function)"
        case .localIssueAskJimmyAbout(let function):
            "Local issue. Ask Jimmy about: \(function)"
        case .contactNotFound(let name):
            "Contact not found: \(name)"
        case .custom(let string):
            "\(string)"
        }
    }
    /// A localized message describing what error occurred.
    var errorDescription: String? { localizedDescription }

    /// A localized message describing the reason for the failure.
    var failureReason: String? { localizedDescription }

    /// A localized message describing how one might recover from the failure.
    var recoverySuggestion: String? { localizedDescription }

    /// A localized message providing "help" text if the user requests help.
    var helpAnchor: String? { localizedDescription }

}
