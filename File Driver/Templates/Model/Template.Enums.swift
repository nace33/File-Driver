//
//  Sort.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//

import Foundation
extension Template {
    enum Group : String, CaseIterable, Hashable, Codable {
        case none, alphabetically, category, subCategory
        var key : KeyPath<Template,String> {
            switch self {
            case .none:
                \.title
            case .alphabetically:
                \.title
            case .category:
                \.label.category
            case .subCategory:
                \.label.subCategory
            }
        }
        var isAlphabetic : Bool {
            self == .alphabetically
        }
    }
    enum Show : String, CaseIterable, Hashable, Codable {
        case drafting, active, retired
        static func isIn(show: Show, _ list: [Show]) -> Bool {
            list.contains(show)
        }
        var asStatus : Template.DriveLabel.Status {
            switch self {
            case .drafting:
                .drafting
            case .active:
                .active
            case .retired:
                .retired
            }
        }
    }
}

