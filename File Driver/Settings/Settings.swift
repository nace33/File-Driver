//
//  Settings.swift
//  TableTest
//
//  Created by Jimmy Nasser on 4/4/25.
//

import Foundation

enum BOF_Settings : String, CaseIterable {
    //Sidebar
   case sidebar, inbox, contacts, forms
    
    enum Key : String {
        //Inbox
        case inboxImmediateFilingKey
        //Contacts
        case contactsDriveIDKey, contactTemplateIDKey, contactsGroupKey, contactIconSizeKey, contactSheetKey, contactsShowVisibleKey, contactsShowHiddenKey, contactsShowPurgeKey, contactsShowColorsKey
        //forms
        case formDriveIDKey, formViewModeKey, formsShowExamplesKey, formsMasterIDKey,formsShowRetiredKey, formsShowActiveKey, formsShowDraftingKey, formsSortKey
        //cases
        case casesFilingShowSeetingsKey, casesFilingTableSortKey, casesFilingTableColumnKey, casesFilingSortKey, casesFilingFilterClosedKey, caseFilingShowStatusColorsKey

        
    }
}
