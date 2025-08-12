//
//  Research.DriveLabel.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//

import SwiftUI

extension Research {
    enum DriveLabel : String {
        case id                  = "5dXa8qxUu5p2F2tXDmsjdRxIU9cj81MWozIRNNEbbFcb"
        case category            = "D789532574" //string
        case subCategory         = "6DEC4DBFE3" //string
        case status              = "4F819CAB86" //list
        case timesUsed           = "A149D237C1"
        
        enum Status : String, CaseIterable {
            case draft = "4F13A2B3BD"
            case review   = "E17086BC74"
            case ready  = "D4C71A8385"
            case retired  = "D453E0BBE8"
            var title : String {
                switch self {
                case .draft:
                    "Draft"
                case .review:
                    "Review"
                case .ready:
                    "Ready"
                case .retired:
                    "Retired"
                }
            }
            var color : Color {
                switch self {
                case .draft:
                    .yellow
                case .review:
                    .orange
                case .ready:
                    .green
                case .retired:
                    .red
                }
            }
        }
    }
    
    
}
