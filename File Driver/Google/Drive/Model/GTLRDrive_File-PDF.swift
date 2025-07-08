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
    var gmailThread: PDFGmailThread? {
        PDFGmailThread(self)
    }
}

extension PDFGmailThread.Person {
    var lowercasedString : String {name.lowercased()+email.lowercased() }
    init?(key:String, value:Any) {
        guard let key   = key.removingPercentEncoding else { return nil }
        guard let value = value as? String else { return nil }
        let split = key.split(separator: " ")
        guard split.count == 2 else { return nil }
        guard let cat   = PDFGmailThread.Person.Category(rawValue: String(split[0])) else { return nil }
        self = PDFGmailThread.Person(name: value, email:  String(split[1].lowercased()), category: cat)
    }

}

extension PDFGmailThread {
    init?(_ file:GTLRDrive_File) {
        guard let appProperties = file.appProperties     else { return nil}
        var removeKeys : [String] = []

        //Intro
        guard let subject           = appProperties.additionalProperty(forName: "subject") as? String else { return nil }
        removeKeys.append("subject")
        guard let printedBy         = appProperties.additionalProperty(forName: "printedBy") as? String else { return nil }
        removeKeys.append("printedBy")
        guard let emailsInThread    = appProperties.additionalProperty(forName: "emailsInThread") as? String else { return nil }
        removeKeys.append("emailsInThread")
        let intro = PDFGmailThread.Intro(subject: subject, emailsInThread: emailsInThread, printedBy: printedBy)

        //Headers
        guard let dateString        = appProperties.additionalProperty(forName: "date")    as? String else { return  nil }
        removeKeys.append("date")
        guard let gtlrDate          = GTLRDateTime(rfc3339String: dateString)                         else { return  nil }

        let people    :[PDFGmailThread.Person ] = appProperties.additionalProperties()
                                     .filter { !removeKeys.contains($0.key)}
                                     .compactMap {
                                            removeKeys.append($0.key)
                                            return .init(key: $0.key, value: $0.value)
                                     }
        
        let header = PDFGmailThread.Header(date: gtlrDate.date, people: people)
        self.init(intro: intro, headers: [header])

        self.source         = file.url
        self.attachments    = []
    }
    var driveAppProperties : GTLRDrive_File_AppProperties {
        let appProperties = GTLRDrive_File_AppProperties()
        addDriveAppProperties(to: appProperties)
        return appProperties
    }

    func addDriveAppProperties(to appProperties:GTLRDrive_File_AppProperties) {
        //There is a 30 key/value limit for the app. -only set most recent email.
        //Erros if > 124 characters, combined in key/value pairs.
        //Do not use Attachments as lengthy URLs will cause error

        //Intro
        appProperties.setAdditionalProperty(intro.subject, forName: "subject")
        appProperties.setAdditionalProperty("\(intro.emailsInThread)", forName: "emailsInThread")
        appProperties.setAdditionalProperty(intro.printedBy, forName: "printedBy")
        
        //Most Recent Header
        appProperties.setAdditionalProperty(GTLRDateTime(date: mostRecentHeader.date).stringValue, forName: "date")
        for contact in mostRecentHeader.people {
            appProperties.setAdditionalProperty("\(contact.name)", forName:"\(contact.category.rawValue)%20\(contact.email)")
        }
    }
}
