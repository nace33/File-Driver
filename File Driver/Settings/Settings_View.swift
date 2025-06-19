//
//  File.swift
//  TableTest
//
//  Created by Jimmy Nasser on 4/4/25.
//

import SwiftUI

struct Settings_View : View {
    
  
    @State private var sheet : BOF_Settings = .sidebar
    
    var body: some View {
        VStack {
            Picker("", selection:$sheet) {
                ForEach(BOF_Settings.allCases, id: \.self) { sheet in
                    Text(sheet.rawValue.camelCaseToWords())
                }
            }
                .labelsHidden().fixedSize().pickerStyle(.segmented)
                .padding(.top)
            
            switch sheet {
            case .filing:
                Settings_Filing()
            case .inbox:
                Settings_Inbox()
            case .sidebar:
                Sidebar_Settings()
            case .contacts:
                Settings_Contacts()
            case .templates:
                Settings_Templates()
            }
        }
            .frame(minWidth:400, minHeight: 400)
    }
}

#Preview {
    Settings_View()
}
