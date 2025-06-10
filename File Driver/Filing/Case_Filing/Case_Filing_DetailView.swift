//
//  Case.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/3/25.
//
import SwiftUI



struct Case_Filing_DetailView : View {
    let aCase : Case
    init(_ aCase: Case) {
        self.aCase = aCase
    }
    
    var body: some View {
        VStack {
            Text(aCase.title)
        }
            .frame(maxHeight: .infinity)
            .navigationTitle(aCase.title)
    }
}
