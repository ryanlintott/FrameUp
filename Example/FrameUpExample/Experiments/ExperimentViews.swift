//
//  ExperimentViews.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-12.
//

import SwiftUI

struct ExperimentViews: View {
    var body: some View {
        #if os(iOS)
        Section {
            NavigationLink(destination: DoubleScrollTabViewExample()) {
                Label("DoubleScrollTabView", systemImage: "scroll")
            }
            
            NavigationLink(destination: HFlowSmartScrollViewExample()) {
                Label("HFlowSmartScrollView", systemImage: "arrow.forward.square")
            }
        } header: {
            Text("Experiments")
        } footer: {
            Text("These are buggy and may crash the app.")
        }
        #else
        EmptyView()
        #endif
    }
}

struct ExperimentViews_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ExperimentViews()
        }
    }
}
