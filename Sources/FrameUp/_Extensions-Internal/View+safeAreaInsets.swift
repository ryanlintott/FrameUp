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
    
    /// Adds an empty safe area region on every edge matching the supplied insets, laid out again at each step when the insets animate.
    ///
    /// A safe area set by ``safeAreaInsets(_:)`` jumps to its new size when it animates. Here the insets are interpolated, so content that respects the safe area moves smoothly.
    /// - Parameter insets: Size of the safe area region to add on each edge.
    /// - Returns: A view with a safe area region matching the supplied insets.
    func animatableSafeAreaInsets(_ insets: EdgeInsets) -> some View {
        modifier(AnimatableSafeAreaInsets(insets: insets))
    }

    /// Sets a fixed frame size that's laid out again at each step when it animates.
    ///
    /// A `frame(width:height:)` change lays the content out at the new size at once, and only animates where it's drawn. Here the size is interpolated, so the content's own layout follows it.
    /// - Parameter size: The frame's size.
    /// - Returns: A view with a frame of that size.
    func animatableFrame(_ size: CGSize) -> some View {
        modifier(AnimatableFrame(size: size))
    }
}

/// Applies a frame size that's interpolated when it animates, so the content is laid out again at each step.
fileprivate struct AnimatableFrame: ViewModifier, @preconcurrency Animatable {
    var size: CGSize

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(size.width, size.height) }
        set { size = CGSize(width: newValue.first, height: newValue.second) }
    }

    func body(content: Content) -> some View {
        content
            /// The size at this step of the animation, for content that places views against the frame's edges.
            .environment(\.fuAnimatedFrameSize, size)
            .frame(width: size.width, height: size.height)
    }
}

/// Applies a safe area that's interpolated when it animates, so the content is laid out again at each step.
fileprivate struct AnimatableSafeAreaInsets: ViewModifier, @preconcurrency Animatable {
    var insets: EdgeInsets

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { .init(.init(insets.top, insets.leading), .init(insets.bottom, insets.trailing)) }
        set { insets = EdgeInsets(top: newValue.first.first, leading: newValue.first.second, bottom: newValue.second.first, trailing: newValue.second.second) }
    }

    func body(content: Content) -> some View {
        content.safeAreaInsets(insets)
    }
}

private struct AnimatedFrameSizeKey: EnvironmentKey {
    static let defaultValue: CGSize? = nil
}

internal extension EnvironmentValues {
    /// The size an `animatableFrame(_:)` has at this step of its animation, such as an `AutoRotatingView`'s turned frame through a turn, or nil outside one.
    var fuAnimatedFrameSize: CGSize? {
        get { self[AnimatedFrameSizeKey.self] }
        set { self[AnimatedFrameSizeKey.self] = newValue }
    }
}
