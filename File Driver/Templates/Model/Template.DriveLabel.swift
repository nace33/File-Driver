//
//  Template.DriveLabel.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import SwiftUI

public
extension Template {
    //Drive Label values
    enum DriveLabel : String {
        case id                  = "jkgGNqsZne1RFsBNYA7hMrTXROf966QGm8RRNNEbbFcb"
        case status              = "1586D33527" //list
        case category            = "FCAD71049E" //string
        case subCategory         = "B60BFF5ABA" //string
        case timesUsed           = "AEECD2D70F" //int
        case lastUsed            = "4D49AE23DE" //date
        case lastUsedBy          = "5AF96C5F86" //string
        case note                = "1A5B9303DF" //string
        case fileDriverReference = "AE21E984A8" //string
        
        enum Status : String, CaseIterable {
            case drafting = "9E11CBB844"
            case active   = "009CC443FC"
            case retired  = "228DDDD17C"
            var title : String {
                switch self {
                case .drafting:
                    "Drafting"
                case .active:
                    "Active"
                case .retired:
                    "Retired"
                }
            }
            var color : Color {
                switch self {
                case .drafting:
                        .yellow
                case .active:
                        .primary
                case .retired:
                        .red
                }
            }
        }
    }
    

}
