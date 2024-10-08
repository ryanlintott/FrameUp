//
//  SmartScrollViewExamples.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-01.
//

import SwiftUI

struct SmartScrollViewExamples: View {
    var body: some View {
        Section {
            #if os(iOS)
            NavigationLink(destination: SmartScrollViewExample()) {
                Label("SmartScroll", systemImage: "scroll")
            }
            
            NavigationLink(destination: SmartScrollViewSimpleExample()) {
                Label("SmartScrollSimple", systemImage: "scroll")
            }
            #else
            UnavailableView()
            #endif
        } header: {
            Text("SmartScrollView")
        }
    }
}

struct SmartScrollViewExamples_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            SmartScrollViewExamples()
        }
    }
}
