//
//  TabMenuExamples.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-01.
//

import SwiftUI

struct TabMenuExamples: View {
    @State private var isFullscreenPresented = false

    var body: some View {
        Section {
            #if os(iOS)
            NavigationLink(destination: TabMenuExampleView()) {
                Label("TabMenu", systemImage: "squares.below.rectangle")
            }

            Button {
                isFullscreenPresented = true
            } label: {
                Label("Fullscreen TabMenu", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .fullScreenCover(isPresented: $isFullscreenPresented) {
                TabMenuFullscreenExampleView()
            }
            #else
            UnavailableView()
            #endif
        } header: {
            Text("TabMenu")
        }
    }
}

struct TabMenuExamples_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TabMenuExamples()
        }
    }
}
