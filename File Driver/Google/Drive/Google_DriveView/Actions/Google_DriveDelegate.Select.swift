//
//  Google_DriveDelegate.Select.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/23/25.
//


//MARK: - Select
import Foundation
import GoogleAPIClientForREST_Drive

extension Google_DriveDelegate {
    ///True when:
    /// 1) One of the following is true
    ///     A) passedIn file != nil (i.e. there is an item selected in the list or the menuItem that passed to this function is set);
    ///     B) stack.last is a folder
    /// 2) And, one of the following is true
    ///     A) mimeTypes is nil
    ///     B) mimeTypes.contains the mimeType of the item in 1 above
    ///
    func canSelect(file:GTLRDrive_File?) -> Bool {
        guard let item = file ?? stack.last else { return false }
        guard let mimeTypes else      { return true  }
        return mimeTypes.contains(item.mime)
    }
    
    func performActionSelect(_ file:GTLRDrive_File?) {
        if actions.contains(.select) {
            selectItem = file ?? stack.last
            print("Select Item: \(String(describing: selectItem?.title))")
        }
    }
}
