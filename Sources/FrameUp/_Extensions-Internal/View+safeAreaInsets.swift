//
//  View+safeAreaInsets.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-10.
//

import SwiftUI

/// An empty non-interactive view used to add a safe area region of a fixed size.
fileprivate func safeAreaSpacer(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
    Color.clear
        .frame(width: width, height: height)
        .allowsHitTesting(false)
}

internal extension View {
    /// Adds an empty safe area region on every edge matching the supplied insets.
    ///
    /// Unlike padding this creates a real safe area region so child views can either respect it or opt out of it with `ignoresSafeArea()`.
    /// - Parameter insets: Size of the safe area region to add on each edge.
    /// - Returns: A view with a safe area region matching the supplied insets.
    func safeAreaInsets(_ insets: EdgeInsets) -> some View {
        self
            .safeAreaInset(edge: .top, spacing: 0) { safeAreaSpacer(height: insets.top) }
            .safeAreaInset(edge: .bottom, spacing: 0) { safeAreaSpacer(height: insets.bottom) }
            .safeAreaInset(edge: .leading, spacing: 0) { safeAreaSpacer(width: insets.leading) }
            .safeAreaInset(edge: .trailing, spacing: 0) { safeAreaSpacer(width: insets.trailing) }
    }
}
