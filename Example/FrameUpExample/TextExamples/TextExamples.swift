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
            if #available(iOS 18, macOS 15, watchOS 11, tvOS 18, visionOS 2, *) {
                NavigationLink(destination: UnclippedTextExample()) {
                    Label("Unclipped Text", systemImage: "character.textbox")
                }
            } else {
                UnavailableView(availableInLaterVersion: true)
            }
        } header: {
            Text("Text")
        }
    }
}

#Preview {
    TextExamples()
}
