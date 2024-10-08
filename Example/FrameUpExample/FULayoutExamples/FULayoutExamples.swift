//
//  FULayoutExamples.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-01.
//

import SwiftUI

struct FULayoutExamples: View {
    @ViewBuilder
    var body: some View {
        Section {
            #if !os(visionOS)
            NavigationLink(destination: HFlowExample()) {
                Label("HFlow", systemImage: "text.word.spacing")
            }
            
            NavigationLink(destination: HFlowBoxExample()) {
                Label("HFlow Boxes", systemImage: "square.grid.3x3")
            }
            
            NavigationLink(destination: VFlowExample()) {
                Label {
                    Text("VFlow")
                } icon: {
                    Image(systemName: "text.word.spacing")
                        .rotation3DEffect(.degrees(180), axis: (1, 1, 0))
                }
            }
            
            NavigationLink(destination: VMasonryExample()) {
                Label("VMasonry", systemImage: "align.vertical.top")
            }
            
            NavigationLink(destination: VMasonryAspectRatioExample()) {
                Label("VMasonry Aspect Ratio", systemImage: "align.vertical.top")
            }
            
            NavigationLink(destination: HMasonryExample()) {
                Label("HMasonry", systemImage: "align.horizontal.left")
            }
            
            NavigationLink(destination: HMasonryAspectRatioExample()) {
                Label("HMasonry Aspect Ratio", systemImage: "align.horizontal.left")
            }
            
            NavigationLink(destination: HStackFULayoutExample()) {
                Label("HStackFULayout", systemImage: "arrow.left.and.right")
            }
            
            NavigationLink(destination: VStackFULayoutExample()) {
                Label("VStackFULayout", systemImage: "arrow.up.and.down")
            }
            
            NavigationLink(destination: ZStackFULayoutExample()) {
                Label("ZStackFULayout", systemImage: "square.3.layers.3d")
            }
            
            NavigationLink(destination: AnyFULayoutSimpleExample()) {
                Label("AnyFULayout Simple", systemImage: "rectangle.3.group")
            }
            
            NavigationLink(destination: AnyFULayoutExample()) {
                Label("AnyFULayout", systemImage: "rectangle.3.group")
            }
            
            NavigationLink(destination: AnyFULayoutHorizontalExample()) {
                Label("AnyFULayout Horizontal", systemImage: "rectangle.3.group")
            }
            
            NavigationLink(destination: FUViewThatFitsExample()) {
                Label("FUViewThatFits", systemImage: "arrow.up.right.and.arrow.down.left.rectangle")
            }
            
            NavigationLink(destination: FULayoutThatFitsExample()) {
                Label("FULayoutThatFits", systemImage: "arrow.up.right.and.arrow.down.left.rectangle")
            }
            
            NavigationLink(destination: CustomFULayoutExample()) {
                Label("Custom FULayout", systemImage: "rectangle.3.group.bubble.left")
            }
            #else
            UnavailableView()
            #endif
        } header: {
            Text("FULayout")
        }
    }
}

struct FULayoutExamples_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                FULayoutExamples()
            }
        }
    }
}
