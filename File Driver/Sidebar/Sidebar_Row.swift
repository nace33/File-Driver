//
//  Sidebar_Row.swift
//  Sidebar_SwiftData
//
//  Created by Jimmy Nasser on 4/4/25.
//

import SwiftUI
import SwiftData
import BOF_SecretSauce

struct Sidebar_Row : View {
    var item : Sidebar_Item
    
    var body: some View {
        Label {
            Text(item.title)
        } icon: {
            item.iconData.favicon(placeholder: item.category.iconString)
        }
    }
}

