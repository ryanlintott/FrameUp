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
        /// SwiftUI can also pass in the default value from views that don't set this key, such as a `safeAreaInset` with empty content, which would otherwise replace the measured size with zero.
        let next = nextValue()
        if next != defaultValue {
            value = next
        }
    }
}

public extension View {
    /// Adds an action to perform when parent view size value changes. This action will also run when the view first appears to send the initial size.
    /// - Parameter action: The action to perform when the size changes. The action closure passes the new value as its parameter.
    /// - Returns: A view that runs the action when its size changes, using `onGeometryChange(for:of:action:)` where it's available and an invisible background `GeometryReader` before that.
    @available(iOS, deprecated: 16, message: "Use onGeometryChange(for:of:action:) with proxy.size.")
    @available(macOS, deprecated: 13, message: "Use onGeometryChange(for:of:action:) with proxy.size.")
    @available(tvOS, deprecated: 16, message: "Use onGeometryChange(for:of:action:) with proxy.size.")
    // Deprecated a version after FrameUp's minimum on watchOS and visionOS, so FrameUp's own uses build without warnings.
    @available(watchOS, deprecated: 10, message: "Use onGeometryChange(for:of:action:) with proxy.size.")
    @available(visionOS, deprecated: 2, message: "Use onGeometryChange(for:of:action:) with proxy.size.")
    @preconcurrency @ViewBuilder func onSizeChange(perform action: @escaping @MainActor (CGSize) -> Void) -> some View {
        if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
            onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newSize in
                action(newSize)
            }
        } else {
            background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SizeKey.self, value: proxy.size)
                }
            )
            .onPreferenceChangeMainActor(SizeKey.self, perform: action)
        }
    }
}
