//
//  TagViewExamples.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-01.
//

import SwiftUI

struct TagViewExamples: View {
    var body: some View {
        Section {
            #if swift(>=6)
            UnavailableView()
            #else
            NavigationLink(destination: TagViewExample()) {
                Label("TagView", systemImage: "tag")
            }
            
            NavigationLink(destination: TagViewForScrollViewExample()) {
                Label("TagViewForScrollView", systemImage: "tag.square")
            }
            #endif
        } header: {
            Text("TagView")
        }
    }
}

struct TagViewExamples_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TagViewExamples()
        }
    }
}
