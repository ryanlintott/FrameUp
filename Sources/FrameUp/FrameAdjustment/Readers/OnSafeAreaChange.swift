//
//  OnSafeAreaChange.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-14.
//

import SwiftUI

/// Used by `onSafeAreaChange` before `onGeometryChange(for:of:action:)` is available.
fileprivate struct SafeAreaInsetsKey: PreferenceKey {
    static let defaultValue: EdgeInsets? = nil
    static func reduce(value: inout EdgeInsets?, nextValue: () -> EdgeInsets?) {
        /// SwiftUI can pass in the default value from views that don't set this key, which would otherwise replace the measured insets.
        value = nextValue() ?? value
    }
}

internal extension View {
    /// Adds an action to perform when the view's safe area insets change. This action also runs when the view first appears, with the initial insets.
    /// - Parameter action: The action to perform when the insets change. The action closure passes the new insets as its parameter.
    /// - Returns: A view that runs the action when its safe area insets change, using `onGeometryChange(for:of:action:)` where it's available and an invisible background `GeometryReader` before that.
    @available(iOS, deprecated: 16, message: "Use onGeometryChange(for:of:action:) with proxy.safeAreaInsets.")
    @available(macOS, deprecated: 13, message: "Use onGeometryChange(for:of:action:) with proxy.safeAreaInsets.")
    @available(tvOS, deprecated: 16, message: "Use onGeometryChange(for:of:action:) with proxy.safeAreaInsets.")
    // Deprecated a version after FrameUp's minimum on watchOS and visionOS, so FrameUp's own uses build without warnings.
    @available(watchOS, deprecated: 10, message: "Use onGeometryChange(for:of:action:) with proxy.safeAreaInsets.")
    @available(visionOS, deprecated: 2, message: "Use onGeometryChange(for:of:action:) with proxy.safeAreaInsets.")
    @ViewBuilder func onSafeAreaChange(perform action: @escaping @MainActor (EdgeInsets) -> Void) -> some View {
        if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
            onGeometryChange(for: EdgeInsets.self) { proxy in
                proxy.safeAreaInsets
            } action: { newInsets in
                action(newInsets)
            }
        } else {
            background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SafeAreaInsetsKey.self, value: proxy.safeAreaInsets)
                }
            )
            .onPreferenceChangeMainActor(SafeAreaInsetsKey.self) { newInsets in
                if let newInsets {
                    action(newInsets)
                }
            }
        }
    }
}
