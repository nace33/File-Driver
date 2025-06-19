//
//  Filing.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI

enum Filing_Error : LocalizedError {
    case filingDriveNotSet
    case urlAlreadyExists
    case transitItemNotFound
    case invalidURL
    case uploadFailed(String)
    case loadFailed(String)
    case googleDriveFileNotFound
    var localizedDescription: String {
        switch self {
        case .filingDriveNotSet:
            return "Filing Drive not set"
        case .urlAlreadyExists:
            return "URL already exists"
        case .transitItemNotFound:
            return "Transit item not found"
        case .invalidURL:
            return "URL is invalid"
        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        case .loadFailed(let reason):
            return "Load failed: \(reason)"
        case .googleDriveFileNotFound:
            return "Google Drive file not found"
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
