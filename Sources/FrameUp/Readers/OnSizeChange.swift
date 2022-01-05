//
//  OnSizeChange.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-11-22.
//

import SwiftUI

/// Used by `onSizeChange`
///
/// Only one key is necessary and works even in nested situations because the value is captured and used inside reader view.
/// Nested views will replace the value before reading it so the correct value should always be sent through.
public struct SizeKey: PreferenceKey {
    public typealias Value = CGSize
    public static let defaultValue: CGSize = .zero
    public static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

public extension View {
    /// Adds an action to perform when parent `View` size value changes.
    /// - Parameter action: The action to perform when the size changes. The action closure passes the new value as its parameter.
    /// - Returns: A view with an invisible background `GeometryReader` that detects and triggers an action when the size changes.
    func onSizeChange(perform action: @escaping (CGSize) -> Void) -> some View {
        self
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SizeKey.self, value: proxy.size)
                }
            )
            .onPreferenceChange(SizeKey.self, perform: action)
    }
}
