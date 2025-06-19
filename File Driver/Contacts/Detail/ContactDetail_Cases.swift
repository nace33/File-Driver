//
//  ContactDetail_Cases.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/13/25.
//

import SwiftUI

struct ContactDetail_Cases: View {
    @Environment(Contact.self) var contact
    @State private var showAddToCase = false
    @State private var showOpenCase  = false

    
    
    var body: some View {
        categoryGridRow
            .padding(.top, (!contact.infoCategories.isEmpty || !contact.fileCategories.isEmpty) ? 12 : 0)
            .sheet(isPresented: $showAddToCase) { AddToCase_Contact(contact:contact) }
            .sheet(isPresented: $showOpenCase) {
                VStack {
                    Text("Jimmy - have this open the case")
                    Button("Close") { showOpenCase.toggle()}
                }.padding(40)
            }

        ForEach(Bindable(contact).cases) { aCase in
            caseGridRow(aCase)
                .padding(.bottom, 8)
                .onTapGesture(count: 2) {
                    showOpenCase.toggle()
                }
        }
    }
}



//MARK: - View Builders
extension ContactDetail_Cases {
    @ViewBuilder var categoryGridRow : some View {
        GridRow {
            Text(" ")
            HStack {
                Button("Cases".uppercased()) { showAddToCase.toggle() }
                    .buttonStyle(.plain)
                    .bold()
                    .font(.caption)
                    .foregroundStyle(.blue)
                Spacer()
            }
        }
    }
    @ViewBuilder func caseGridRow(_ aCase:Binding<Contact.Case>) -> some View {
        GridRow {
            Image(systemName: aCase.wrappedValue.caseImageString)
                .resizable()
                .frame(width:17, height:17)
                .padding(.trailing, 8)
                .padding(.leading)
                .foregroundStyle(.blue)
            HStack {
                HStack {
                    Text(aCase.wrappedValue.name)
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
        }
    }
}


#Preview {
    ContactDetail_Cases()
}
