//
//  Case.SortBy.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/24/25.
//

import Foundation

extension Case {
    enum SortBy : String, CaseIterable {
        case category, status, name
        var title : String { rawValue.capitalized }
    }
}
