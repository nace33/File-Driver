//
//  Settings.swift
//  TableTest
//
//  Created by Jimmy Nasser on 4/4/25.
//

import Foundation

enum BOF_Settings : String, CaseIterable {
    //Sidebar
   case sidebar, filing, inbox, contacts, templates, cases
    
    enum Key : String {
        //General
        case textSuggestionStyle
        //filing
        case filingDrive, filingAutoRename, filingAutoRenameComponents, filingAutoRenameEmailComponents, filingSuggestionLimit, filingSuggestionPartialTagMatch, filingShowMultipleFilenames
 
        //Inbox
        case inboxImmediateFilingKey
        //Contacts
        case contactsDriveIDKey, contactTemplateIDKey, contactsSortKey, contactsLastNameFirst, contactIconSizeKey, contactSheetKey, contactsShowVisibleKey, contactsShowHiddenKey, contactsShowPurgeKey, contactsShowColorsKey, contactsShowImage

        //templates
        case templateDriveID, templatesShowDrafting, templatesShowActive, templatesShowRetired, templatesSortKey, templatesListSort
        
        //cases
        case casesFilingShowSeetingsKey, casesFilingTableSortKey, casesFilingTableColumnKey, casesFilingSortKey, casesFilingFilterClosedKey, caseFilingShowStatusColorsKey
        case caseConsultationDriveID, caseTemplateID, casesSort
        
        
        //Research
        case researchDriveID, researchTemplateID
    }
}


