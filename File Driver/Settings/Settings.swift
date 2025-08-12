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
        case filingDrive, filingAutoRenameFiles, filingAutoRenameEmails, filingAutoRenameComponents, filingAutoRenameEmailComponents, filingAllowSuggestions, filingSuggestionLimit, filingFormContactMatch, filingFormTagMatch
 
        //Inbox
        case inboxImmediateFilingKey
        //Contacts
        case contactsDriveID, contactsGroupBy, contactsShow, contactsLastNameFirst, contactIconSizeKey, contactSheetKey, contactsShowColorsKey, contactsShowImage

        //templates
        case templateDriveID, templatesSortBy, templateGroupBy, templatesShow
        
        //cases
        case casesFilingShowSeetingsKey, casesFilingTableSortKey, casesFilingTableColumnKey, casesFilingSortKey, casesFilingFilterClosedKey, caseFilingShowStatusColorsKey
        case caseConsultationDriveID, casesGroupBy, casesShow
        
        
        //Research
        case researchDriveID, researchGroupBy, researchShow
    }
}


