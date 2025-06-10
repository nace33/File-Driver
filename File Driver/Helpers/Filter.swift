//
//  TokenFilter.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//
import SwiftUI


@Observable
class Filter  {
    var string    : String     = "" {
        didSet {
            if tokenPrefix != nil { checkShouldInsertToken() }
        }
    }
    var tokens    : [Token]    = []
    var allTokens : [Token]    = []
    
 
    struct Token : Identifiable, Hashable {
        let id : String
        let title : String
        let rawValue : String
        let prefix : TokenPrefix
        
        init?(prefix:TokenPrefix, title:String, rawValue:String) {
            guard title.isEmpty    == false else { return nil }
            guard rawValue.isEmpty == false else { return nil }
            
            
            self.id       = UUID().uuidString
            self.title    = title
            self.rawValue = rawValue
            self.prefix   = prefix
        }

        enum TokenPrefix : String, CaseIterable {
            case hashTag    = "#"
            case dollarSign = "$"
        }
    }

    

    
    var hasTokenPrefix : Bool {
        guard string.isEmpty == false else { return false }
        let prefixes = Token.TokenPrefix.allCases.map (\.rawValue)
        let possibleToken = String(string.first!)
        guard prefixes.filter({ $0 == possibleToken}).count > 0 else { return false }
        return true
    }
    var tokenPrefix: Token.TokenPrefix? {
        guard hasTokenPrefix else { return nil }
        let prefixString = String(string.first!)
        return Token.TokenPrefix(rawValue: prefixString)
    }
    
    func tokens(for prefix:Token.TokenPrefix) -> [Token] {
        allTokens.filter { $0.prefix == prefix}
    }
    var tokenSuggestions : [Token] {
        guard let prefix = tokenPrefix else { return [] }
        let tokens = tokens(for: prefix)
        let tokenString = String(string.dropFirst())
        if tokenString.isEmpty { return tokens }
        else {
            return tokens.filter { $0.title.ciHasPrefix(tokenString)}
        }
    }
    
    
    //Used in Swift UI
    func checkShouldInsertToken() {
        guard let tokenPrefix else { return }
        guard let suggestedToken = tokenSuggestions.first else { return }
        
        let value = String(string.dropFirst())
        
        if value == suggestedToken.title {
            tokens.append(suggestedToken)
            string = string.replacingOccurrences(of: tokenPrefix.rawValue+value, with: "")
        }
    }
    @ViewBuilder var searchSuggestions: some View {
        if let tokenPrefix {
            ForEach(tokenSuggestions) { token in
                Text(token.title)
                    .searchCompletion(tokenPrefix.rawValue+token.title)
            }
        }
    }
}
