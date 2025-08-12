
//
//  UserDefaults.swift
//  File Driver
//
//  Created by Jimmy Nasser on 8/10/25.
//
import Foundation

public
extension UserDefaults {
    static func getEnum<T>(forKey key: String) -> T? where T : Codable {
        guard let string = UserDefaults.standard.object(forKey:key) as? String else { return nil }
        guard let data   = string.data(using: .utf8) else { return nil }
        guard let results = try? JSONDecoder().decode(T.self, from: data) else { return nil }
        return results
    }
    static func getEnums<T>(forKey key: String) -> [T] where T : Codable {
        guard let string = UserDefaults.standard.object(forKey:key) as? String else { return [] }
        guard let data   = string.data(using: .utf8) else {return []}
        guard let results = try? JSONDecoder().decode([T].self, from: data) else { return [] }
        return results
    }
}
