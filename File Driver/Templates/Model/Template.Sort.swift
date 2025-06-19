//
//  Sort.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/14/25.
//


extension Template {
    enum Sort : String, CaseIterable, Hashable, Codable {
        case alphabetically, category, subCategory
    }
}