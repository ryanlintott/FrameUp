//
//  FlippingViewExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-09-15.
//

import FrameUp
import SwiftUI

struct FlippingViewExample: View {
    @State private var flips: Int = 0
    var isFaceUp: Bool { flips.isMultiple(of: 2) }
    @State private var axis: Axis = .horizontal
    
    var body: some View {
        VStack {
            FlippingView(
                axis,
                flips: $flips
            ) {
                ZStack {
                    Color.blue
                    Text("Front")
                }
                .cornerRadius(20)
            } back: {
                ZStack {
                    Color.red
                    Text("Back")
                }
                .cornerRadius(20)
            }
            #if os(visionOS)
            .frame(maxWidth: 200, maxHeight: 200)
            .frame(maxDepth: 200, alignment: .center)
            #endif
            .font(.largeTitle)
            .padding(40)
            
            VStack {
                HStack {
                    Text("Flips: \(flips)")
                    Spacer()
                    Text("Face \(isFaceUp ? "Up" : "Down")")
                }
                
                HStack {
                    Text("Axis")
                    Picker("Axis", selection: $axis) {
                        ForEach(Axis.allCases, id: \.self) { axis in
                            Text("\(axis.description)")
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                HStack {
                    Text("Programmatic flip")
                    Button("-1") { flips -= 1 }
                    Button("+1") { flips += 1 }
                }
            }
            .padding()
        }
    }
}

#Preview {
    FlippingViewExample()
}
