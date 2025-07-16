//
//  Filing.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI

enum Filing_Error : LocalizedError {

    case destinationNotSelected
    case caseNotSelected
    case filesNotMoved(String)
    case filesMovedButSpreadsheetNotUpdated(String)
    case suggestionsNotUpdated(String)
    case uploadFailed(String, String)
    var localizedDescription: String {
        switch self {
        case .destinationNotSelected:
            "Filing Folder not selected"
        case .caseNotSelected:
            "Case not selected"
        case .filesMovedButSpreadsheetNotUpdated(let reason):
            "Files moved but case files were not updated:\n\(reason).\nYou will need to audit the case if re-trying does not succeed."
        case .filesNotMoved(let reason):
            "Files not moved:\n\(reason)"
        case .suggestionsNotUpdated(let reason):
            "Suggestions not updated:\n\(reason)"
        case .uploadFailed(let filename, let reason):
            "Upload failed for \(filename):\n\(reason)"
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
