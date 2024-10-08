//
//  SizeMatchingViewExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2024-07-10.
//

import FrameUp
import SwiftUI

struct SizeMatchingViewExample: View {
    @State private var size: CGSize? = nil
    
    var body: some View {
        ZStack {
            Color.blue.frame(width: 300, height: 300)
            
            Text("Size to match")
                .onSizeChange {
                    size = $0
                }
        }
        .accessibilityElement(children: .combine)
        .overlay(
            Rectangle()
                .stroke(Color.red)
                .frame(maxWidth: size?.width, maxHeight: size?.height)
        )
    }
}

#Preview {
    SizeMatchingViewExample()
}
