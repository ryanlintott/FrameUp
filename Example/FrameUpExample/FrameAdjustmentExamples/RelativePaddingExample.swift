//
//  RelativePaddingExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-01-31.
//

import FrameUp
import SwiftUI

struct RelativePaddingExample: View {
    @State private var isHorizontal: Bool = true
    @State private var padding: CGFloat = 0.1
    
    var axis: Edge.Set {
        isHorizontal ? .horizontal : .vertical
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            
            Color.green
                .relativePadding(axis, padding)
                .background(Color.red)
                .padding(80)
            
            Spacer(minLength: 0)
            
            VStack(alignment: .leading) {
                Picker(selection: $isHorizontal) {
                    ForEach([true, false], id: \.self) { isHorizontal in
                        Text(isHorizontal ? "Horizontal" : "Vertical")
                    }
                } label: {
                    Text("Axis")
                }
                .pickerStyle(.segmented)
                
                HStack {
                    Text("Padding \(padding * 100, specifier: "%.0f")%")
                    #if os(tvOS)
                    Button("-") { padding = max(-0.5, padding - 0.1) }
                    Button("+") { padding = min(0.5, padding + 0.1) }
                    #else
                    Slider(value: $padding, in: -0.5...0.5)
                    #endif
                }
            }
            .padding()
        }
        .navigationTitle("RelativePadding")
    }
}

struct RelativePaddingExample_Previews: PreviewProvider {
    static var previews: some View {
        RelativePaddingExample()
    }
}
