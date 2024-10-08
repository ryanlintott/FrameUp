//
//  LayoutThatFitsExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-10-29.
//

import FrameUp
import SwiftUI

@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
struct LayoutThatFitsExample: View {
    @State private var maxWidth: CGFloat = 200
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack {
                Text("Above")
                
                LayoutThatFits(in: .horizontal, [HStackLayout(), VStackLayout()]) {
                    Color.green.frame(width: 50, height: 50)
                    Color.yellow.frame(width: 50, height: 200)
                    Color.blue.frame(width: 50, height: 100)
                }
                .frame(width: maxWidth)
                .border(Color.red)
                
                Text("Below")
            }
            .animation(.default, value: maxWidth)
            
            Spacer()
            
            HStack {
                #if os(tvOS)
                Text("Max Width \(maxWidth)")
                Button("-") { maxWidth = max(50, maxWidth - 50) }
                Button("+") { maxWidth = min(350, maxWidth + 50) }
                #else
                Text("Max Width")
                Slider(value: $maxWidth, in: 50...350)
                    .padding()
                #endif
            }
            .padding()
        }
        .navigationTitle("LayoutThatFits")
    }
}

@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
struct LayoutThatFitsExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LayoutThatFitsExample()
        }
    }
}
