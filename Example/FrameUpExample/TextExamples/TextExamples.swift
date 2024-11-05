//
//  TextExamples.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2024-09-20.
//

import SwiftUI

struct TextExamples: View {
    var body: some View {
        Section {
            #if canImport(UIKit)
            NavigationLink(destination: HairSpaceJustifiedTextExample()) {
                Label("HairSpaceJustifiedText", systemImage: "character.textbox")
            }
            #else
            UnavailableView()
            #endif
            
            /// This check ensures this code only builds in Xcode 16+
            #if compiler(>=6)
            if #available(iOS 18, macOS 15, watchOS 11, tvOS 18, visionOS 2, *) {
                NavigationLink(destination: UnclippedTextExample()) {
                    Label("Unclipped Text", systemImage: "character.textbox")
                }
            }
            #endif
        } header: {
            Text("Text")
        }
    }
}

#Preview {
    TextExamples()
}
