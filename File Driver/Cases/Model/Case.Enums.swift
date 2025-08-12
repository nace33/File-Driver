//
//  Case.SortBy.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import Foundation

extension Case {
    enum GroupBy : String, CaseIterable {
        case category, status, name
        var title : String { rawValue.camelCaseToWords }
        var key : KeyPath<Case,String> {
            switch self {
            case .category:
                \.label.category.title
            case .status:
                \.label.status.title
            case .name:
                \.label.title
            }
        }
        var isAlphabetic : Bool {
            self == .name
        }
    }
    
    enum Show : String, CaseIterable, Codable {
        case consultation, investigation, active, stayed, closed
        var title : String { rawValue.camelCaseToWords }
        static func isIn(show: Show, _ list: [Show]) -> Bool {
            list.contains(show)
        }
        var asStatus : Case.DriveLabel.Label.Field.Status {
            switch self {
            case .consultation:
                Case.DriveLabel.Label.Field.Status.consultation
            case .investigation:
                Case.DriveLabel.Label.Field.Status.investigation
            case .active:
                Case.DriveLabel.Label.Field.Status.active
            case .stayed:
                Case.DriveLabel.Label.Field.Status.stayed
            case .closed:
                Case.DriveLabel.Label.Field.Status.closed
            }
        }
    }
}
