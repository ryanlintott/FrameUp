//
//  View+onPreferenceChange.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2024-11-28.
//

import SwiftUI

internal extension View {
    #if compiler(>=6.0) && compiler(<6.1)
    /// Adds an action to perform when the specified preference key's value
    /// changes. This action is wrapped in a MainActor Task for Swift compiler 6.0 to 6.0.3 due to the Sendable requirement for those versions.
    ///
    /// - Parameters:
    ///   - key: The key to monitor for value changes.
    ///   - action: The action to perform when the value for `key` changes. The
    ///     `action` closure passes the new value as its parameter.
    ///
    /// - Returns: A view that triggers `action` when the value for `key`
    ///   changes.
    @preconcurrency @inlinable nonisolated func onPreferenceChangeMainActor<K>(_ key: K.Type = K.self, perform action: @escaping @MainActor (K.Value) -> Void) -> some View where K : PreferenceKey, K.Value : Equatable & Sendable {
        onPreferenceChange(key) { newValue in
            Task { @MainActor in
                action(newValue)
            }
        }
    }
    #else
    /// Adds an action to perform when the specified preference key's value
    /// changes. This action is wrapped in a MainActor Task for Swift compiler 6.0 to 6.0.3 due to the Sendable requirement for those versions.
    ///
    /// - Parameters:
    ///   - key: The key to monitor for value changes.
    ///   - action: The action to perform when the value for `key` changes. The
    ///     `action` closure passes the new value as its parameter.
    ///
    /// - Returns: A view that triggers `action` when the value for `key`
    ///   changes.
    @inlinable nonisolated func onPreferenceChangeMainActor<K>(_ key: K.Type = K.self, perform action: @escaping (K.Value) -> Void) -> some View where K : PreferenceKey, K.Value : Equatable {
        onPreferenceChange(key, perform: action)
    }
    #endif
}
