//
//  HFlowBoxLayoutExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2024-05-23.
//

import FrameUp
import SwiftUI

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
struct HFlowBoxLayoutExample: View {
    @State private var boxes = [1,2,3,4,5]
    @State private var horizontalAlignment: FUHorizontalAlignment = .leading
    let verticalAlignment: FUVerticalAlignment = .top
    
    var alignment: FUAlignment { .init(horizontal: horizontalAlignment, vertical: verticalAlignment)}
    
    var body: some View {
        VStack {
            Color.blue.overlay(
                ScrollView {
                    HFlowLayout(alignment: alignment) {
                        ForEach(boxes, id: \.self) { box in
                            Color.red
                                .frame(width: 80, height: 80)
                        }
                    }
                }
                .animation(.default, value: boxes)
                .animation(.default, value: alignment)
            )
            VStack {
                HStack {
                    Button("Remove Box") { if !boxes.isEmpty { boxes.removeLast() } }
                        .padding()
                    Button("Add Box") { boxes.append((boxes.max() ?? 1) + 1) }
                        .padding()
                }
                
                Picker("Horizontal Alignment", selection: $horizontalAlignment) {
                    ForEach(FUHorizontalAlignment.allCases) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
        }
        .navigationTitle("HFlowLayout Boxes")
    }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
#Preview {
    HFlowBoxLayoutExample()
}
