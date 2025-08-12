//
//  Sheets.Enums.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/12/25.
//

import Foundation
import GoogleAPIClientForREST_Sheets



extension Sheets {
    enum WrapStrategy : String, CaseIterable {
        case overflow, clip, wrap
        var rawValue: String {
            switch self {
            case .overflow:
                kGTLRSheets_CellFormat_WrapStrategy_OverflowCell
            case .clip:
                kGTLRSheets_CellFormat_WrapStrategy_Clip
            case .wrap:
                kGTLRSheets_CellFormat_WrapStrategy_Wrap
            }
        }
    }
    enum Vertical : String, CaseIterable {
        case top, middle, bottom
        var rawValue: String {
            switch self {
            case .top:
                kGTLRSheets_CellFormat_VerticalAlignment_Top
            case .middle:
                kGTLRSheets_CellFormat_VerticalAlignment_Middle
            case .bottom:
                kGTLRSheets_CellFormat_VerticalAlignment_Bottom
            }
        }
    }
    enum Horizontal : String, CaseIterable {
        case left, center, right
        var rawValue: String {
            switch self {
            case .left:
                kGTLRSheets_CellFormat_HorizontalAlignment_Left
            case .center:
                kGTLRSheets_CellFormat_HorizontalAlignment_Center
            case .right:
                kGTLRSheets_CellFormat_HorizontalAlignment_Right
            }
        }
    }
}
