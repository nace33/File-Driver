//
//  NLF_Form_Category.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/29/25.
//

import Foundation



//MARK: Helpers
extension NLF_Form {

    enum Category : String, CaseIterable {
        case affidavit, money, discovery, exhibit, letter, pleading, workProduct, other
        init?(string:String) {
            if let cat = Category(rawValue: string) {
                self = cat
            }
            else if let cat = Category(rawValue: string.wordsToCamelCase()) {
                self = cat
            }
            else {
                return nil
            }
        }
    }
    
    enum SubCategory : String, CaseIterable {
        //Affidavit
        case records, estate
        //Billing
        case disbursement, invoice, payment
        //Discovery
        case interrogatory, request, admission, response
        //Exhibit
        case medicalRecords, medicalBills, calculation
        //Letter
        case letterhead, representation, recordsRequest, billsRequest, recordsAndBillsRequest
        
        
        static func subCategories(for category:Category) -> [SubCategory] {
            switch category {
            case .affidavit:
                [.estate, .records]
            case .money:
                [.disbursement, .invoice, .payment]
            case .discovery:
                [.interrogatory, .request, .admission, .response]
            case .exhibit:
                [.medicalRecords, .medicalBills, .calculation]
            case .letter:
                [.letterhead, .representation, .recordsRequest, .billsRequest, .recordsAndBillsRequest]
            case .workProduct:
                fallthrough
            case .pleading:
                fallthrough
            case .other:
                fallthrough
            @unknown default:
                []
            }
        }
    }
    
}
