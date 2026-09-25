//
//  View+containerCornerRadii.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

internal extension View {
    /// Sets the container shape to the corners of the container a proxy's view fills, each moved to the corner it lines up with after a rotation.
    ///
    /// `AutoRotatingView` uses this to hand its content the container's corners turned with it, so `concentricCornerRadii`, `ConcentricRectangle` and `ContainerRelativeShape` inside the rotation round the corners that sit on the container's rounded ones.
    ///
    /// The modifier is always applied where it is available, even before the container's radii can be read, so the view's identity doesn't change as they settle over several layout passes. Until then the container shape has square corners.
    /// - Parameters:
    ///   - proxy: A proxy for a view that fills the container, outside the rotation. It shares the container's corners, so its concentric radii are the container's own.
    ///   - angle: Rotation applied to this view.
    ///   - layoutDirection: Layout direction used to resolve leading and trailing corners.
    /// - Returns: A view with the container shape set, or the unchanged view before iOS 27.
    @ViewBuilder
    func containerCornerRadii(of proxy: GeometryProxy, rotatedBy angle: Angle, layoutDirection: LayoutDirection) -> some View {
#if canImport(SwiftUICore, _version: 8.0.84)
        if #available(iOS 27, macOS 27, tvOS 27, watchOS 27, visionOS 27, *) {
            let radii = proxy.concentricCornerRadii?.rotated(by: angle, layoutDirection: layoutDirection) ?? RectangleCornerRadii()
            self.containerShape(UnevenRoundedRectangle(cornerRadii: radii, style: .continuous))
        } else {
            self
        }
#else
        self
#endif
    }
}
