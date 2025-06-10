//
//  GTLRDrive_Drive_Ext.swift
//  Nasser Law Firm
//
//  Created by Jimmy Nasser on 3/23/25.
//

import Foundation
import GoogleAPIClientForREST_Drive


extension GTLRDrive_Drive : @retroactive Identifiable   {
    public var id: String { identifier ?? "No Identifier Found"}
    public var title : String { name ?? "No Name" }
}
