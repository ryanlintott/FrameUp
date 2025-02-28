//
//  View+onPreferenceChange.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2024-11-28.
//

import SwiftUI

struct OnPreferenceChangeUpdatingBinding<K>: ViewModifier where K : PreferenceKey, K.Value : Equatable & Sendable {
    let key: K.Type
    @Binding var value: K.Value
    var predicate: @Sendable (_ currentValue: K.Value, _ newValue: K.Value) -> Bool
    
    func body(content: Content) -> some View {
        content
            .onPreferenceChange(key) { [$value] newValue in
                if predicate($value.wrappedValue, newValue) {
                    $value.wrappedValue = newValue
                }
            }
    }
}

internal extension View {
    /// Updating a binding based on a predicate.
    @preconcurrency nonisolated func onPreferenceChange<K>(_ key: K.Type = K.self, update value: Binding<K.Value>, where predicate: @escaping @Sendable (_ oldValue: K.Value, _ newValue: K.Value) -> Bool) -> some View where K : PreferenceKey, K.Value : Equatable & Sendable {
        modifier(OnPreferenceChangeUpdatingBinding(key: key, value: value, predicate: predicate))
        
    }
    
    /// Updating a binding on every change.
    @preconcurrency @inlinable nonisolated func onPreferenceChange<K>(_ key: K.Type = K.self, update value: Binding<K.Value>) -> some View where K : PreferenceKey, K.Value : Equatable & Sendable {
        onPreferenceChange(key) { newValue in
            value.wrappedValue = newValue
        }
    }
    
    /// Wrap the action in a MainActor Task.
    @preconcurrency @inlinable nonisolated func onPreferenceChangeMainActor<K>(_ key: K.Type = K.self, perform action: @escaping @MainActor (K.Value) -> Void) -> some View where K : PreferenceKey, K.Value : Equatable & Sendable {
        onPreferenceChange(key) { newValue in
            Task { @MainActor in
                action(newValue)
            }
        }
    }
}
