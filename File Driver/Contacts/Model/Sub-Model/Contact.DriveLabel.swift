//
//  Contact.DriveLabel.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/10/25.
//

import SwiftUI

public
extension Contact {
    //Drive Label values
    enum DriveLabel : String {
        case id         = "BaFRDNO8jAiL39Wx68qKr6PfszyBtEeIR5WRNNEbbFcb"
        case firstName  = "F6D8BBFF5F"
        case lastName   = "521B29B6BE"    //should be empty if isBusiness is true
        case groupName  = "6E01CA2EF2" //general groupings (Medical Provider, IME etc ..., Clients)
        case iconID     = "B9BF3AD95C"
        case status     = "EE27255012"
        case client     = "B28D1DBE70"
        
        
       public enum Status : String, CaseIterable {
            case active   = "57DCEB050D"
            case hidden    = "79E8A8180C"
            case purge     = "AEF41D8229"
            var title : String {
                switch self {
                case .active:
                    "Active"
                case .hidden:
                    "Hidden"
                case .purge:
                    "Delete"
                }
            }
            init?(title:String) {
                if let s = Status.allCases.first(where: {$0.title.lowercased() == title.lowercased()}) {
                    self = s
                } else {
                    return nil
                }
            }
            static func color(_ string:String, isHeader:Bool = false) -> Color {
                guard let s = Status(title: string) else { return .green }
                return s.color(isHeader: isHeader)
            }
            static func color(_ status:Status, isHeader:Bool = false) -> Color {
                switch status {
                case .active:
                    isHeader ? .green : .primary
                case .hidden:
                    .orange
                case .purge:
                    .red
                }
            }
            func color(isHeader:Bool = false) -> Color {
                Status.color(self, isHeader:isHeader)
            }
            var actionTitle : String {
                switch self {
                case .active:
                    "Show Contact"
                case .hidden:
                    "Hide Contact"
                case .purge:
                    "Mark for Deletion"
                }
            }
        }
        
        public enum ClientStatus : String, CaseIterable {
            case notAClient       = "06A42E30F9"
            case potentialClient  = "E0D3744824"
            case activeClient     = "5888DEA7EB"
            case previousClient   = "CAB2ACE9BF"
            case rejectedClient   = "1BA63D5963"
            var title : String {
                switch self {
                case .notAClient:
                    "Not A Client"
                case .potentialClient:
                    "Potential Client"
                case .activeClient:
                    "Active Client"
                case .previousClient:
                    "Previous Client"
                case .rejectedClient:
                    "Rejected Client"
                }
            }
        }
    }
}

