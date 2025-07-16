//
//  GTLRDrive_File-PDF.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/5/25.
//

import Foundation
import GoogleAPIClientForREST_Drive
import BOF_SecretSauce

extension GTLRDrive_File {
    var gmailThread: EmailThread? {
        EmailThread.init(appProperties: appProperties)
    }
}



//MARK: - App Properites
///Pro: Not user editable, code will not break once set
///Con: Only searchable via File Driver App, limited to 30 key/value pairs of 124 bytes each.
extension EmailThread {
    init?(appProperties:GTLRDrive_File_AppProperties?) {
        guard let appProperties   else { return nil}

        //Intro
        guard let subject           = appProperties.additionalProperty(forName: "subject")    as? String else { return nil }
//        print("Subject: \(subject)")
        //Headers
        guard let dateStr           = appProperties.additionalProperty(forName: "date")       as? String else { return  nil }
        guard let gtlrDate          = GTLRDateTime(rfc3339String: dateStr)                               else { return  nil }
        guard let dateString        = appProperties.additionalProperty(forName: "dateString") as? String else { return  nil }

        let people : [EmailThread.Person] = appProperties.additionalProperties()
            .compactMap { key, value in
                guard key.isValidEmail else { return nil }
                return EmailThread.Person(key: key, value: value)
            }
            .sorted(by: {$0.category.intValue < $1.category.intValue})
        let dateInfo = EmailThread.DateInfo(dateString:dateString, date: gtlrDate.date)
        let header   = EmailThread.Header(dateInfo: dateInfo, people: people, string: "")

        self = EmailThread(subject: subject, headers: [header])
    }
    var driveAppProperties : GTLRDrive_File_AppProperties {
        let appProperties = GTLRDrive_File_AppProperties()
        
        //Subject
        let sub = subject.isValidURL ? "" : subject
        appProperties.setAdditionalProperty(sub, forName: "subject")
        
        //Most Recent Header is the most recent header in the full->uniqueHeaders array.
        if let mostRecentHeader = mostRecentHeader(style: .full, addMostLikelyName: true)  {
            if let dateInfo = mostRecentHeader.dateInfo {
                appProperties.setAdditionalProperty(GTLRDateTime(date: dateInfo.date).rfc3339String, forName: "date")
                appProperties.setAdditionalProperty(dateInfo.string, forName: "dateString")
            }
//            let people = mostRecentHeader.people.sorted(by: {$0.category.intValue < $1.category.intValue})
        }
        
        for contact in uniquePeople(in:fullHeaders, addMostLikelyName: true) {
            let value = "\(contact.category.rawValue)\(EmailThread.personCatSeperator)\(contact.name)"
            if let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                appProperties.setAdditionalProperty(encodedValue, forName:contact.email)
            }
        }
        
        return appProperties
    }
}

///String Constants
fileprivate
extension EmailThread {
    static var personCatSeperator   : String { "_" }
}

//MARK: - Person
///used to create person from Description or App Property data
extension EmailThread.Person {
    var lowercasedString : String {name.lowercased()+email.lowercased() }
    init?(key:String, value:Any) {
        //key is the email address
        //value should be in format to_NameIfAny
        //where '_' is the personCatSeperator
        guard let str   = value as? String else { return nil }
        guard let name = str.removingPercentEncoding else { return nil }
        
        //get the part of the string before the personCatSeperator
        let nameSplit = name.split(separator:EmailThread.personCatSeperator)
        guard nameSplit.count > 0 else { return nil }
        
        //split[0] is the category (which may be all there is if there is no name
        let catSplit = String(nameSplit[0])
        let cat      = EmailThread.Person.Category(rawValue:catSplit) ?? .unknown
        
        //if there was not split[1], then the name is empty
        let useName  = nameSplit.count == 2 ? String(nameSplit[1]) : ""
        self         = EmailThread.Person(email: key, location: 0, name:useName, category:cat)
    
    }
}
