//
//  FolderMenu.swift
//  File Driver
//
//  Created by Jimmy Nasser on 4/16/25.
//

import SwiftUI

//MARK: Menu
extension Case {
    @ViewBuilder public func folderMenu(title:String = "Folders", /*showSuggestions:Bool = false,*/ selected:@escaping(Folder) -> ()) -> some View {
        Menu(title) {
            ForEach(rootFolders) { root in
                FolderMenu(aCase: self, folder: root, selected: selected)
            }
//            if showSuggestions {
//
//                let suggestions = folderRootSuggestions
//                if suggestions.count > 0 {
//                    if rootFolders.isNotEmpty {
//                        Divider()
//                    }
//                    Text("Suggestions")
//                    ForEach(suggestions) { suggestion in
//                        Button(suggestion.name) { selected(suggestion) }
//                    }
//                }
//            }
        }
    }
    
    
    struct FolderMenu : View {
        var aCase  : Case
        var folder : Case.Folder
        var selected:(Case.Folder) -> ()
        var body: some View {
            let children = aCase.children(of: folder)
            if children.isEmpty {
                Button(folder.name) { selected(folder )}
            } else {
                Menu(folder.name) {
                    ForEach(children) { child in
                        FolderMenu(aCase: aCase, folder: child, selected: selected)
                    }
                } primaryAction: {
                    selected(folder)
                }
            }
        }
    }
}
