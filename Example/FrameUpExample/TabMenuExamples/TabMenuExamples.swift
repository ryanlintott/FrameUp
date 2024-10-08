//
//  TabMenuExamples.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-01.
//

import SwiftUI

struct TabMenuExamples: View {
    var body: some View {
        Section {
            #if os(iOS)
            NavigationLink(destination: TabMenuExampleView()) {
                Label("TabMenu", systemImage: "squares.below.rectangle")
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
