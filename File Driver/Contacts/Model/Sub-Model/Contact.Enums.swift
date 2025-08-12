//
//  Contacts.Enums.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/10/25.
//

import SwiftUI

public extension Contact {
    enum Group : String, CaseIterable {
        case firstName, lastName, client, group, status
        var title : String { rawValue.camelCaseToWords }
        var isAlphabetic : Bool {
            self == .firstName || self == .lastName
        }
        var key : KeyPath<Contact,String> {
            switch self {
            case .firstName:
                \.label.firstName
            case .lastName:
                \.label.nameReversed
            case .client:
                \.label.client.title
            case .group:
                \.label.groupName
            case .status:
                \.label.status.title
            }
        }
    }
    
    enum Show : String, CaseIterable, Hashable, Codable {
        case active, hidden, purge, lastNameFirst, profileImage, statusColors
        var title : String { rawValue.camelCaseToWords }
        static var filterOptions : [Self] { [.active, .hidden, .purge ]}
        static var displayOptions : [Self]{ [.lastNameFirst, .profileImage, .statusColors]}
        static func isIn(show: Show, _ list: [Show]) -> Bool {
            list.contains(show)
        }
        var asStatus : Contact.DriveLabel.Status? {
            switch self {
            case .active:
                .active
            case .hidden:
                .hidden
            case .purge:
                .purge
            default:
                nil
            }
        }
    }
}
