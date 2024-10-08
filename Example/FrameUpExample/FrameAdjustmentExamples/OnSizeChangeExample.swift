//
//  OnSizeChangeExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-11-22.
//

import FrameUp
import SwiftUI

struct OnSizeChangeExample: View {
    @State private var maxWidth: CGFloat = 100
    @State private var maxHeight: CGFloat = 100
    @State private var size: CGSize = .zero
    @State private var changes: Int = .zero
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("As the view changes size, a closure runs to update the values below:")
                
                Text("Size Changes: \(changes)")
                    .font(.headline)
                Text("Size: \(String(format: "%.0f", size.width)) x \(String(format: "%.0f", size.height))")
                    .font(.headline)
            }
            .padding()
            
            Spacer()
            
            Color.blue
                .onSizeChange { size in
                    self.size = size
                    self.changes += 1
                }
                .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                .animation(.default, value: maxWidth)
                .animation(.default, value: maxHeight)
            
            Spacer()
            
            VStack {
                HStack {
                    #if os(tvOS)
                    Text("Max Width \(String(format: "%.0f", maxWidth))")
                    Button("-") { maxWidth = max(50, maxWidth - 50) }
                    Button("+") { maxWidth = min(500, maxWidth + 50) }
                    #else
                    Stepper("Max Width \(String(format: "%.0f", maxWidth))", value: $maxWidth, in: 50...500, step: 50)
                        .padding(.horizontal)
                    #endif
                }
                
                HStack {
                    #if os(tvOS)
                    Text("Max Height \(String(format: "%.0f", maxHeight))")
                    Button("-") { maxHeight = max(50, maxHeight - 50) }
                    Button("+") { maxHeight = min(800, maxHeight + 50) }
                    #else
                    Stepper("Max Height \(String(format: "%.0f", maxHeight))", value: $maxHeight, in: 50...800, step: 50)
                        .padding(.horizontal)
                    #endif
                }
            }
            .padding()
        }
        .navigationTitle("onSizeChange")
    }
}

struct OnSizeChangeExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OnSizeChangeExample()
        }
    }
}
