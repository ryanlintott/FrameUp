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
    @State private var width: CGFloat = 200
    
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
                .frame(width: width)
                .border(Color.red)
                
                Text("Below")
            }
            .animation(.default, value: width)
            
            Spacer()
            
            HStack {
                #if os(tvOS)
                Text("Width \(width)")
                Button("-") { width = max(50, width - 50) }
                Button("+") { width = min(350, width + 50) }
                #else
                Text("Width")
                Slider(value: $width, in: 50...350)
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
