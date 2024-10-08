//
//  OverlappingImageVerticalExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-01.
//

import FrameUp
import SwiftUI

struct OverlappingImageVerticalExample: View {
    let image = Image(systemName: "star.square")
    
    @State private var top: CGFloat = 0.1
    @State private var bottom: CGFloat = 0.25
    
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                Text("Overlapping Image")
                    .font(.system(size: 50))
                Rectangle()
                    .frame(height: 5)
                
                OverlappingImage(image, aspectRatio: 1.0, top: top, bottom: bottom)
                    .foregroundColor(.blue.opacity(0.5))
                    .padding(.horizontal, 50)
                    .zIndex(1)
                
                VStack {
                    Text("The image above will overlap content above and below with an inset based on a percent of the image height. This allows the overlap to occur in the same location regardless of scale.")
                        .padding(20)
                }
                .background(Color.gray)
                .padding(3)
                .background(Color.red)
            }
            .frame(width: 300, height: 500)
            
            Spacer()
            
            VStack {
                HStack {
                    Text("Top \(top * 100, specifier: "%.0f")%")
                    #if os(tvOS)
                    Button("-") { top = max(0, top - 0.1) }
                    Button("+") { top = min(1, top + 0.1) }
                    #else
                    Text("")
                    Slider(value: $top, in: 0...1)
                    #endif
                }
                
                HStack {
                    Text("Bottom \(bottom * 100, specifier: "%.0f")%")
                    #if os(tvOS)
                    Button("-") { bottom = max(0, bottom - 0.1) }
                    Button("+") { bottom = min(1, bottom + 0.1) }
                    #else
                    Text("")
                    Slider(value: $bottom, in: 0...1)
                    #endif
                }
            }
            .padding()
        }
        .navigationTitle("OverlapVertical")
    }
}

struct OverlappingImageVerticalExample_Previews: PreviewProvider {
    static var previews: some View {
        OverlappingImageVerticalExample()
    }
}
