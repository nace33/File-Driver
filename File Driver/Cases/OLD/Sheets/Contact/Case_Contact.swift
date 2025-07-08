//
//  Case_Contact.swift
//  FD_Filing
//
//  Created by Jimmy Nasser on 4/16/25.
//

import Foundation


//MARK: Contacts
extension Case_OLD {
    func load(contacts:[[String]]) {
        self.contacts = contacts.compactMap {  Contact(row: $0)   }
    }
    var rootContacts : [Contact] {
        contacts.filter{$0.parentID.isEmpty && $0.category == .contact }
    }
    func children(of contact:Contact) -> [Contact] {
        contacts.filter{$0.parentID == contact.id && $0.category == .contact}
    }
    func details(of contact:Contact) -> [Contact] {
        contacts.filter{$0.parentID == contact.id }
    }


    struct Contact : Identifiable, Hashable  {
        let id      : String
        var parentID: String
        var category: Category
        var label   : String
        var value   : String
        
        init?(row:[String]) {
            guard row.count == 5 else { return nil }
            guard let cat = Category(rawValue: row[2]) else { return nil }
            id       = row[0]
            parentID = row[1]
            category = cat
            label    = row[3]
            value    = row[4]
        }
    }
}

extension Case_OLD.Contact {
    enum Category : String, CaseIterable {
        case contact
        case centralID //for linking to a central database
        case folder, photo    //where to save documents in this case (multiple contacts can save to same place)
        case note
        case role
        case email, phone, address, fax, social, website
        case date
        case number
        case credential
        case other
        static var info : [Category] {[.email, .phone, .address, .fax, .social, .website ]}
        var title : String { rawValue.camelCaseToWords()}
        
    }
    enum Role : String, CaseIterable {
        case potentialClient, client, plaintiff, defendant
        case witness, eyeWitness, expert
        case medicalProvider
        case insurer, subrogee
        case coCounsel, opposingCounsel, judge, mediator
        case staff
        case other
        
        var title : String { rawValue.camelCaseToWords() }
    }
    enum NumberType : String, CaseIterable {
        case driversLicense, socialSecurity, policyNumber, claimNumber, accountNumber, employeeNumber, amount, other
        var title : String { rawValue.camelCaseToWords() }
    }
    enum DateType : String, CaseIterable {
        case dateOfBirth, dateOfDeath, dateOfInjury, dateBegan, dateEnded, date
        var title : String { rawValue.camelCaseToWords() }
    }
    enum InfoLabel : String, CaseIterable {
        case home, work, mobile
        var title : String { rawValue.capitalized }
    }
    enum SocialLabel : String, CaseIterable {
        case facebook, twitter, snapchat, linkedin, instagram, youtube, other
        var title : String { rawValue.capitalized }
    }
    enum InsurerCoverage : String, CaseIterable {
        case um, uim, property, automobile, liability, umbrella, heath, disability, other
        var title : String { rawValue.capitalized }
    }
}
