//
//  HappyDog.swift
//  File Driver
//
//  Created by Jimmy Nasser on 6/16/25.
//



import SwiftUI

struct HappyDog : View {
    let text  : String
    let color : Color
    init(_ text: String = "", color:Color = .primary) {
        self.text = text
        self.color = color
    }
    @State private var counter: Int = 0
          
    
    var body: some View {
        VStack {
            Spacer()
            Text(text)
                .bold()
                .font(.title2)
                .foregroundStyle(color)
//                .shadow(color:.secondary, radius: 5)

            Image(assetName: "HappyDog")
                .resizable( resizingMode: .stretch)
                .frame(width:200, height: 200)
                .cornerRadius(10) // Inner corner radius
                .padding(2) // Width of the border
                .background(Color.primary) // Color of the border
                .cornerRadius(10) // Outer corner radius
                .onTapGesture {
                    counter += 1
                }
                .confettiCannon(trigger: $counter)
//                .displayConfetti(isActive:.constant(true))

            Spacer()
        }
        .onAppear() {
            counter += 1
        }
        .frame(maxWidth: .infinity)
    }

}
