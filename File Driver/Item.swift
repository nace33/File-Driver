//
//  Item.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/4/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
