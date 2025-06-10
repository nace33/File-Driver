//
//  NLF_Form_Sort.swift
//  File Driver
//
//  Created by Jimmy Nasser on 5/28/25.
//

import SwiftUI

struct NLF_Form_Sort: View {
    @AppStorage(BOF_Settings.Key.formsSortKey.rawValue) var formsSort : Form_Sort = .category
    
    
    var body: some View {
        Picker("Sort By", selection:$formsSort) {
            ForEach(Form_Sort.allCases, id:\.self) { sort in
                Text(sort.rawValue.capitalized).tag(sort)
            }
        }
            .fixedSize()

    }
}

#Preview {
    NLF_Form_Sort()
}
