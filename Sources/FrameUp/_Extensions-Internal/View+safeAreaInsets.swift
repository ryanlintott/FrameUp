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

/// Adds a safe area matching the supplied insets, rotated into the local space of a view rotated by the supplied angle.
///
/// The angle is animatable so the safe area turns with the rotation frame by frame. Animating the insets themselves would instead interpolate between two resting positions, moving the centre of the safe area off the axis of rotation part way through a turn.
fileprivate struct RotatedSafeAreaInsets: ViewModifier, Animatable {
    var angle: Angle
    var insets: EdgeInsets
    var layoutDirection: LayoutDirection
    
    nonisolated var animatableData: Double {
        get { angle.degrees }
        set { angle = .degrees(newValue) }
    }
    
    func body(content: Content) -> some View {
        content.safeAreaInsets(insets.rotated(by: angle, layoutDirection: layoutDirection))
    }
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
    
    /// Adds an empty safe area region matching the supplied insets, moved to the edges they line up with in the local space of a view rotated by the supplied angle.
    ///
    /// The angle animates so the safe area turns with the rotation rather than interpolating between the resting positions at either end.
    /// - Parameters:
    ///   - insets: Size of the safe area region to add on each edge, measured outside the rotation.
    ///   - angle: Rotation applied to this view.
    ///   - layoutDirection: Layout direction used to resolve leading and trailing insets into left and right ones before rotating.
    /// - Returns: A view with a safe area region matching the supplied insets as seen from inside the rotation.
    func safeAreaInsets(_ insets: EdgeInsets, rotatedBy angle: Angle, layoutDirection: LayoutDirection) -> some View {
        modifier(RotatedSafeAreaInsets(angle: angle, insets: insets, layoutDirection: layoutDirection))
    }
}
