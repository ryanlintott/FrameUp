//
//  FlippingViewExamples.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-01.
//

import SwiftUI

struct FlippingViewExamples: View {
    var body: some View {
        Section {
            #if os(visionOS)
            NavigationLink(destination: TwoSided3DViewExample()) {
                Label("rotation3DEffect(back:)", systemImage: "arrow.uturn.right.square")
            }
            
            NavigationLink(destination: TwoSidedViewExample()) {
                Label("perspectiveRotationEffect(back:)", systemImage: "arrow.uturn.right.square")
            }
            #else
            NavigationLink(destination: TwoSidedViewExample()) {
                Label("rotation3DEffect(back:)", systemImage: "arrow.uturn.right.square")
            }
            #endif
            
            NavigationLink(destination: FlippingViewExample()) {
                Label("FlippingView", systemImage: "arrow.uturn.right.square")
            }
            
            #if os(visionOS)
            NavigationLink(destination: PerspectiveFlippingViewExample()) {
                Label("PerspectiveFlippingView", systemImage: "arrow.uturn.right.square")
            }
            #endif
        } header: {
            Text("FlippingView")
        }
    }
}

#Preview {
    List {
        FlippingViewExamples()
    }
}
