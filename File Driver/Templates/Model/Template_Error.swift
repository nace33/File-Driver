//
//  Template_Error.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import Foundation


enum Template_Error : LocalizedError {
    case noDriveID
    case invalidMethodParameters(String)
    case localIssueAskJimmyAbout(String)
    case templateNotFound(String)
    case driveLabelMissing(String)
    case custom(String)
    case unableToUpdateStatus
    case unableToUpdateCategory
    var localizedDescription: String {
        switch self {
        case .noDriveID:
            "No Drive to save templates to is set"
        case .invalidMethodParameters(let function):
            "Invalid method parameters: \(function)"
        case .localIssueAskJimmyAbout(let function):
            "Local issue. Ask Jimmy about: \(function)"
        case .templateNotFound(let name):
            "Template not found: \(name)"
        case .driveLabelMissing(let reason):
            "Drive label missing: \(reason)"
        case .custom(let string):
            "\(string)"
        case .unableToUpdateStatus:
            "Unable to update status"
        case .unableToUpdateCategory:
            "Unable to update category"
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
