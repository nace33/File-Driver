//
//  Sheet.StringsRow.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/26/25.
//

import Foundation


//MARK: - Protocol
protocol SheetStringsRow : Identifiable {
    var sheetID : Int                    { get }
    init?(strings:[String])
    var strings : [String] { get }
    
}
