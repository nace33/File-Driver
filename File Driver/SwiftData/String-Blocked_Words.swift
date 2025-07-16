//
//  String-Blocked_Words.swift
//  File Driver
//
//  Created by Jimmy Nasser on 7/12/25.
//

import Foundation

extension String {
    
    static var blockedWords : [String] {
        let blockedWordsString = UserDefaults.standard.string(forKey: BOF_Settings.Key.filingAutoRenameBlockedWords.rawValue) ?? ""
        let blockedWords = blockedWordsString.split(separator: ",")
                                             .compactMap { String($0).replacingOccurrences(of: "[\"", with: "").replacingOccurrences(of: "\"]", with: "")}
        return blockedWords
    }
    func remove(blockedWords:[String], trim:Bool) -> String {
          var string = self
          for blockedWord in blockedWords  {
              if trim {
                  string = string.replacingOccurrences(of: blockedWord, with: "")
                                 .trimmingCharacters(in: .whitespaces)
              } else {
                  string = string.replacingOccurrences(of: blockedWord, with: "")
              }
          }
        return string
    }
    
    var removeBlockedWords: String {
        remove(blockedWords: Self.blockedWords, trim: true)
    }
}
