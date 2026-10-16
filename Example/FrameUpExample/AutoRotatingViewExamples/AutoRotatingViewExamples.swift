//
//  AutoRotatingViewExamples.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-01.
//

import SwiftUI

struct AutoRotatingViewExamples: View {
    var body: some View {
        Section {
            #if os(iOS)
            NavigationLink(destination: AutoRotatingViewExample()) {
                Label("AutoRotatingView", systemImage: "arrow.turn.up.forward.iphone")
            }
            NavigationLink(destination: AutoRotatingViewFullscreenExample()) {
                Label("Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            NavigationLink(destination: NestedAutoRotatingViewExample()) {
                Label("Nested", systemImage: "square.on.square")
            }
            NavigationLink(destination: ContainerGeometryProbeExample()) {
                Label("Container Geometry Probe", systemImage: "rectangle.dashed")
            }
            NavigationLink(destination: RotationDirectionExample()) {
                Label("Rotation Direction", systemImage: "arrow.clockwise")
            }
            if #available(iOS 17, *) {
                NavigationLink(destination: InnerHoldProbeExample()) {
                    Label("Inner Hold Probe", systemImage: "lock.rotation")
                }
            }
            #else
            UnavailableView()
            #endif
        } header: {
            Text("AutoRotatingView")
        }
    }
}

struct AutoRotatingViewExamples_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                AutoRotatingViewExamples()
            }
        }
    }
}
