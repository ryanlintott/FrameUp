//
//  View+onPreferenceChange.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2024-11-28.
//

import SwiftUI

internal extension View {
    /// Adds an action to perform when the specified preference key's value
    /// changes. When compiling with Swift 6.0.3, this action is wrapped in a
    /// MainActor task to work around Xcode 16.2's `Sendable` requirement.
    ///
    /// - Parameters:
    ///   - key: The key to monitor for value changes.
    ///   - action: The action to perform when the value for `key` changes. The
    ///     `action` closure passes the new value as its parameter.
    ///
    /// - Returns: A view that triggers `action` when the value for `key`
    ///   changes.
    #if compiler(>=6.0.3) && compiler(<6.1)
    @inlinable nonisolated func onPreferenceChangeMainActor<K>(_ key: K.Type = K.self, perform action: @escaping @MainActor (K.Value) -> Void) -> some View where K : PreferenceKey, K.Value : Equatable & Sendable {
        onPreferenceChange(key) { newValue in
            Task { @MainActor in
                action(newValue)
            }
        }
    }
    #else
    @inlinable nonisolated func onPreferenceChangeMainActor<K>(_ key: K.Type = K.self, perform action: @escaping (K.Value) -> Void) -> some View where K : PreferenceKey, K.Value : Equatable {
        onPreferenceChange(key, perform: action)
    }
    #endif
}
