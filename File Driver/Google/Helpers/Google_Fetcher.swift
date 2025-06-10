//
//  Google_Fetcher.swift
//  Cases
//
//  Created by Jimmy Nasser on 8/10/23.
//

import Foundation
import GoogleAPIClientForRESTCore

class Google_Fetcher<T> {
    let service : GTLRService
    let scopes  : [String]
    
    var ticket : GTLRServiceTicket?
    var continuation : CheckedContinuation<T?, Error>?
   
    typealias Progress =  (Float) -> ()
    let progress : Progress?
    
    typealias Cancel =  () -> ()
    let cancel : Cancel?
    
    init(service:GTLRService, scopes:[String], progress:Progress? = nil, cancel:Cancel? = nil) {
        self.service = service
        self.scopes = scopes
        self.progress = progress
        self.cancel = cancel
    }
    
    
    func cancel(title:String, description:String) {
        ticket?.cancel()
        if let cancel {
            DispatchQueue.main.async {
                Google.shared.isLoading = false
                cancel()
            }
        } else {
            DispatchQueue.main.async {
                Google.shared.isLoading = false
            }
        }
        continuation?.resume(returning: nil)
        continuation = nil
    
    }
}




