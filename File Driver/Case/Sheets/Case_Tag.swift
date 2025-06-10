//
//  Case_Tag.swift
//  FD_Filing
//
//  Created by Jimmy Nasser on 4/16/25.
//

//MARK: Tags
extension Case {
    func load(tags:[[String]]) {
        self.tags = tags.compactMap { Tag(row: $0)}
    }



    struct Tag : Identifiable  {
        var id      : String { name } //Drive ID of folder
        var name    : String //name of folder
        var note    : String
        init?(row:[String]) {
            guard row.count == 2 else { return nil }
            name     = row[0]
            note     = row[1]
        }
    }
}
