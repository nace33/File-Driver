//
//  Google_Label.swift
//  Cases
//
//  Created by Jimmy Nasser on 8/10/23.
//

import Foundation
import GoogleAPIClientForREST_DriveLabels

extension GTLRDriveLabels_GoogleAppsDriveLabelsV2Label : @retroactive Identifiable {
    
    public var id : String { identifier ?? "Error Getting Label ID" }
    var title : String { properties?.title ?? "No Title" }
    
    
    func field(id:String) -> GTLRDriveLabels_GoogleAppsDriveLabelsV2Field? {
        fields?.first(where: { $0.identifier == id })
    }
    
    //Selection
    var selectionFields : [GTLRDriveLabels_GoogleAppsDriveLabelsV2Field]? {
        fields?.compactMap { $0 }
    }
    var allSelectionIDsAndValues : [(id:String, value:String)]? {
        selectionFields?.filter ({ $0.selectionIDsAndValues != nil }).flatMap { $0.selectionIDsAndValues! }
    }
    func selectionChoices(fieldID:String) -> [String]? {
        field(id: fieldID)?.selectionIDsAndValues?.map {$0.value }
    }
}


//MARK: Field Selections
extension GTLRDriveLabels_GoogleAppsDriveLabelsV2Field {
    var selectionIDs : [String]? {
        selectionOptions?.choices?.compactMap { $0.identifier }
    }
    var selectionStrings : [String]? {
        selectionOptions?.choices?.compactMap { $0.properties }.compactMap { $0.displayName }
    }
    func selectionString(id:String) -> String? {
        selectionOptions?.choices?.first(where: {$0.identifier == id})?.properties?.displayName
    }
    func selectionID(displayName:String) -> String? {
        selectionOptions?.choices?.first(where: {$0.properties?.displayName == displayName})?.identifier
    }
    var selectionIDsAndValues : [(id:String, value:String)]? {
        selectionIDs?.compactMap({ id in
//            print("ID: \(id)")
            if let string = selectionString(id: id) {
//                print("\tString:\(string)")
                return (id, string)
            }
            return nil
        })
    }
    
    //MARK: Helpers
    var category : Category {
        if textOptions != nil {
            return .text
        }
        else if dateOptions != nil {
            return .date
        }
        else if integerOptions != nil {
            return .integer
        }
        else if userOptions != nil {
            return .user
        }
        else if selectionOptions != nil {
            return .list
        }
        else { return .error }
    }
    enum Category : String {
        case text, date, user, list, integer, error
    }
    

}



