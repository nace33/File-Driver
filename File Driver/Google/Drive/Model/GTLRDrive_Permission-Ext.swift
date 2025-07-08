//
//  GTLRDrive_Permission.EXT.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/2/25.
//

import Foundation
import GoogleAPIClientForREST_Drive

extension GTLRDrive_Permission :@retroactive Identifiable {
    public var id   : String { identifier ?? UUID().uuidString }
    var name : String { displayName ?? "No Name"}
    var firstName : String { displayName?.components(separatedBy: " ").first ?? "No Name"}
}
