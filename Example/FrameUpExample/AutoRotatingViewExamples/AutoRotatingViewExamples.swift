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
