//
//  GoogleSheetColumn.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/12/25.
//

import Foundation

protocol GoogleSheetColumn :Equatable {
    static func columns(for sheet:any GoogleSheet) -> [Self]
    var rawValue     : String { get }
}

extension GoogleSheetColumn {
    func columns(for sheet:any GoogleSheet) -> [Self] { Self.columns(for: sheet)  }
    func index(in sheet:any GoogleSheet) -> Int? { columns(for: sheet).firstIndex(of: self) }
}
