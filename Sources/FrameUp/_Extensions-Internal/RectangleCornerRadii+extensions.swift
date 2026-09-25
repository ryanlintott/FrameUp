//
//  RectangleCornerRadii+extensions.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
internal extension RectangleCornerRadii {
    /// These radii as seen by a view that has been rotated by the supplied angle, with each radius moved to the corner it lines up with.
    ///
    /// A container's corners are not always the same, so a rotated view has to round the corners that now sit on the container's rounded ones.
    ///
    ///     // A view rotated a quarter turn clockwise has its top leading corner on the parent's top trailing corner.
    ///     RectangleCornerRadii(topLeading: 8, bottomLeading: 8, bottomTrailing: 59, topTrailing: 59)
    ///         .rotated(by: .degrees(90), layoutDirection: .leftToRight) // topLeading: 59, bottomTrailing: 8
    ///
    /// Angles are matched to the nearest quarter turn, as with `EdgeInsets.rotated(by:layoutDirection:)`.
    /// - Parameters:
    ///   - angle: Rotation applied to the view these radii are being moved into.
    ///   - layoutDirection: Layout direction used to resolve leading and trailing corners into left and right ones before rotating.
    /// - Returns: Radii moved to the corners they line up with after the rotation.
    func rotated(by angle: Angle, layoutDirection: LayoutDirection) -> RectangleCornerRadii {
        let corners = FUCorners(topLeading: topLeading, topTrailing: topTrailing, bottomLeading: bottomLeading, bottomTrailing: bottomTrailing)
            .rotated(by: angle, layoutDirection: layoutDirection)
        return RectangleCornerRadii(
            topLeading: corners.topLeading,
            bottomLeading: corners.bottomLeading,
            bottomTrailing: corners.bottomTrailing,
            topTrailing: corners.topTrailing
        )
    }
}
