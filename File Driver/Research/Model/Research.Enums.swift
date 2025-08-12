//
//  Research.Enums.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/11/25.
//

import Foundation
extension Research {
    enum Group : String, CaseIterable, Hashable, Codable {
        case none, alphabetically, category, subCategory
        var key : KeyPath<Research,String> {
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
        case draft, review, ready, retired
        var title : String { rawValue.camelCaseToWords}
        static func isIn(show: Show, _ list: [Show]) -> Bool {
            list.contains(show)
        }
        var asStatus : Research.DriveLabel.Status {
            switch self {
            case .draft:
                .draft
            case .review:
                .review
            case .ready:
                .ready
            case .retired:
                .retired
            }
        }
    }
}


