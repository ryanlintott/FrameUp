//
//  LayoutExamples.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-01.
//

import SwiftUI

struct LayoutExamples: View {
    var body: some View {
        Section {
            if #available(iOS 16, macOS 13, watchOS 9, tvOS 16, *) {
                NavigationLink(destination: HFlowLayoutExample()) {
                    Label("HFlowLayout", systemImage: "text.word.spacing")
                }
                
                NavigationLink(destination: HFlowBoxLayoutExample()) {
                    Label("HFlowBoxLayout", systemImage: "square.grid.3x3")
                }
                
                NavigationLink(destination: VFlowLayoutExample()) {
                    Label {
                        Text("VFlowLayout")
                    } icon: {
                        Image(systemName: "text.word.spacing")
                            .rotation3DEffect(.degrees(180), axis: (1, 1, 0))
                    }
                }
                
                NavigationLink(destination: VMasonryLayoutExample()) {
                    Label("VMasonryLayout", systemImage: "align.vertical.top")
                }
                
                NavigationLink(destination: HMasonryLayoutExample()) {
                    Label("HMasonryLayout", systemImage: "align.horizontal.left")
                }
                
                NavigationLink(destination: LayoutThatFitsExample()) {
                    Label("LayoutThatFits", systemImage: "arrow.up.right.and.arrow.down.left.rectangle")
                }
            } else {
                UnavailableView(availableInLaterVersion: true)
            }
        } header: {
            Text("Layout")
        }
    }
}

struct LayoutExamples_Previews: PreviewProvider {
    static var previews: some View {
        List {
            LayoutExamples()
        }
    }
}
