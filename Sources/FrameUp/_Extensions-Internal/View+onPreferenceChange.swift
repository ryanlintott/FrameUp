//
//  SwiftUIView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2024-11-28.
//

import SwiftUI

internal extension View {
    @preconcurrency @inlinable nonisolated func onPreferenceChangeMainActor<K>(_ key: K.Type = K.self, perform action: @escaping @MainActor (K.Value) -> Void) -> some View where K : PreferenceKey, K.Value : Equatable & Sendable {
        #if swift(>=6)
        onPreferenceChange(key) { newValue in
            Task { @MainActor in
                action(newValue)
            }
        }
        #else
        onPreferenceChange(key, perform: action)
        #endif
    }
}
