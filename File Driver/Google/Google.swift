//
//  Google.swift
//  Cases
//
//  Created by Jimmy Nasser on 8/10/23.
//
import SwiftUI
import GoogleAPIClientForRESTCore
import GoogleSignIn

//@MainActor 
@Observable
final class Google {
    //Singleton
    static let shared: Google = {
        let instance = Google()
        // setup code
        instance.restoreLogin()
        return instance
    }()
    
    //GENERAL
    var isLoading = false
    
    //Objects
    var drive  : Google_Drive  { Google_Drive.shared  }
    var labels : Google_Labels { Google_Labels.shared }

    //User
    var user : GIDGoogleUser?
    var avatar = Image(systemName: "person")
    var loginStatus : Google.SignInStatus = .readyToSignIn
}


//MARK: Query Execute
extension Google {
    static func executeBatch<T>(_ batch:GTLRBatchQuery, fetcher:Google_Fetcher<T>) async throws -> T? {
        guard !(batch.queries?.isEmpty ?? true) else {
            print("No Batch Queries To Execute - Returning NIL")
            throw Google_Error.noBathQueriesProvided
        }
        return try await execute(batch, fetcher:fetcher)
    }
    static func execute<T>(_ query:GTLRQueryProtocol, fetcher:Google_Fetcher<T>)  async throws -> T? {
        guard let user = shared.user else {
            throw Google_Error.notLoggedIntoGoogle
        }
        shared.isLoading = true

        do {
            _ = try await canProceed(scopes: fetcher.scopes)
        } catch {
            shared.isLoading = false
            throw error
        }
        

        fetcher.service.authorizer = user.fetcherAuthorizer
        fetcher.service.shouldFetchNextPages = true
       
        query.executionParameters.uploadProgressBlock = { _, bytesUploaded, totalToUpload in
            let b = Float(bytesUploaded)
            let t = Float(totalToUpload)
            fetcher.progress?(b/t)
        }
   
        do {
            return try await withCheckedThrowingContinuation { continuation in
                
                let serviceTicket = fetcher.service.executeQuery(query) { ticket, object, error in
//                    print("Object: \(object)")
//                    print("Error: \(error)")
                    shared.isLoading = false
                    guard error == nil else {
                        continuation.resume(throwing: error!)
                        return
                    }

                    continuation.resume(returning: object as? T)
                }
                fetcher.ticket = serviceTicket
                fetcher.continuation = continuation
            }
        } catch {
            print("\n\n****\(#function)\nError: \(error.localizedDescription)\n****")
            throw error
        }
    }
}

