//
//  KeyboardHeightExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2024-02-02.
//

import FrameUp
import SwiftUI

struct KeyboardHeightExample: View {
    /// This environment value was added in ContentView
    @Environment(\.keyboardHeight) var keyboardHeight
    @State private var text = ""
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Keyboard animation is close to the iOS keyboard movement on the iPhone but on iPad there is a delay when dismissing the keyboard. The value will always be zero on macOS, watchOS and tvOS")
            
            if #available(iOS 15, tvOS 15, macOS 12, watchOS 8, *) {
                Text("Keyboard Height: \(keyboardHeight, format: .number.rounded())")
                    .animation(nil, value: keyboardHeight)
            }
            Spacer()
            
            TextField("Moves with Keyboard", text: $text)
                #if os(iOS)
                .textFieldStyle(.roundedBorder)
                #endif
            
            Color.blue.opacity(0.5)
                .overlay(Text("Ignores Keyboard"))
                /// The frame height adjusts from a fixed value to the keyboard height when its visible.
                .frame(height: keyboardHeight == 0 ? 100 : keyboardHeight)
        }
        /// The stack needs to be at the bottom of the container
        .frame(maxHeight: .infinity, alignment: .bottom)
        /// The whole stack your view is in needs to ignore the safe area
        .ignoresSafeArea(.keyboard)
        /// You may need to add animation if environment variable was added outside a NavigationView
        .animation(.keyboard, value: keyboardHeight)
        #if !os(macOS) && !os(tvOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationTitle("KeyboardHeight")
    }
}

#Preview {
    KeyboardHeightExample()
        .keyboardHeightEnvironmentValue()
}
