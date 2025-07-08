//
//  Drive.Delegate.Sort.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/7/25.
//

import Foundation
import BOF_SecretSauce

//MARK: - Delete
extension DriveDelegate {
    enum SortBy : String, CaseIterable, Codable {
        case ascending, descending, lastModified, fileType
        var title : String { rawValue.camelCaseToWords() }
    }

}
