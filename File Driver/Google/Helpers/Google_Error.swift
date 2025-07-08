//
//  Google_Error.swift
//  Cases
//
//  Created by Jimmy Nasser on 8/11/23.
//

import Foundation

enum Google_Error: LocalizedError {
    case loginError(String)
    case didNotProvidePropertiesToMethod(String)
    case failedToAddScopes([String])
    case noBathQueriesProvided
    case batchDidNotCompletlySucceed//I don't thinks this is possible since the result would be an error from the google's server
    case driveIDIsEmpty(String)
    case driveParentIDIsEmpty(String)
    case driveCallSuceededButDidNotReturnAsExpected(String)
    case driveCallSuceededButReturnTypeDoesNotMatch //likey the problems is fetcher specified the wrong return type
    
    case sheetNotFound(String, [String])
    case failedToShareNoUserSpecified
    case failedToUpdateLabel
    case notLoggedIntoGoogle
    case noAccessToThisItem
    case itemNotFound
    case noDriveIDFound
    case itemAlreadyExists

    case gmailMessageIDNotFound
    case gmailMessageIsNotPDF
    case gmailAttachmentDownloadError
    case gmailMessageNotFetched
    
    case userCanceled
    case unableToCreateSheetFileChip
    var errorDescription: String? {
        switch self {
        case .loginError(let message):
            "Login Failed Because: \n\(message)"
        case .didNotProvidePropertiesToMethod(let method):
            "Did Not Provide Properties To Method \n\(method)"
        case .failedToAddScopes(let scopes):
            "Failed to Add Permission For Scopes\n\(scopes.joined(separator: ", "))"
        case .noBathQueriesProvided:
            "No Batch Queries Provided"
        case .batchDidNotCompletlySucceed:
            "Batch did not completly succeed"
        case .driveIDIsEmpty(let title):
            "Drive ID is Empty for \(title)"
        case .driveParentIDIsEmpty(let title):
            "Drive Parent ID is Empty for \(title)"
        case .driveCallSuceededButDidNotReturnAsExpected(let method):
            "The Call to the API worked, but the return value is different than what was expected. \(method)"
        case .driveCallSuceededButReturnTypeDoesNotMatch:
            "The Call to the API worked, but the return type is different than what was expected."
        case .failedToShareNoUserSpecified:
            "Must specify a user to share this drive item with."
        case .failedToUpdateLabel:
            "Unable to update the drive label."
        case .notLoggedIntoGoogle:
            "Not Logged Into Google"
        case .noAccessToThisItem:
            "Access Prohibited"
        case .noDriveIDFound:
            "No Drive ID Found"
        case .itemNotFound:
            "Item Not Found"
        case .itemAlreadyExists:
            "Item Already Exists"
        case .gmailMessageIDNotFound:
            "No Gmail Message Found"
        case .gmailMessageIsNotPDF:
            "Cannot Get Attachments from Non-PDF Gmail Download"
        case .gmailAttachmentDownloadError:
            "Could not download Gmail Attachment"
        case .gmailMessageNotFetched:
            "Failed to fetch Message"
        case .sheetNotFound(let sheetName, let sheets):
            "Sheet \(sheetName) not found in \(sheets.joined(separator: ", "))"
        case .userCanceled:
            "User Canceled"
        case .unableToCreateSheetFileChip:
            "Unable to create a File Chip from Cell Data"
        }
    }
}
