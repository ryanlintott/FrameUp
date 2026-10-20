//
//  AutoRotatingGeometryProxy.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

#if os(iOS)
/// Container corner geometry turned with an `AutoRotatingView`'s content, which SwiftUI's own `GeometryProxy` reports unturned.
///
///     AutoRotatingView([.portrait]) { geometry in
///         Content()
///             .padding(.top, geometry.containerCornerInsets.topTrailing.height)
///     }
///
/// Size, safe area and reserved regions are already correct in a `GeometryReader` inside the content. The values describe the whole content frame, not smaller views inside it.
public struct AutoRotatingGeometryProxy: Equatable, Sendable {
    /// The container's corner insets, moved to the content corners they sit on.
    let cornerInsets: PhysicalCornerInsets
    /// The container's corner radii, moved to the content corners they sit on, or nil where they can't be read.
    let cornerRadii: PhysicalCornerRadii?
    /// The layout direction the public corners are named in.
    let layoutDirection: LayoutDirection

    #if compiler(>=6.2)
    /// The container's corner insets for each corner of the content, turned with the content.
    @available(iOS 26, *)
    public var containerCornerInsets: RectangleCornerInsets {
        RectangleCornerInsets(cornerInsets, layoutDirection: layoutDirection)
    }
    #endif

    #if canImport(SwiftUICore, _version: 8.0.84)
    /// The container's corner radii for each corner of the content, turned with the content, or nil if SwiftUI doesn't report any.
    ///
    /// Use these in place of `ConcentricRectangle`, which SwiftUI resolves against the unturned container.
    @available(iOS 27, *)
    public var concentricCornerRadii: RectangleCornerRadii? {
        cornerRadii.map { RectangleCornerRadii($0, layoutDirection: layoutDirection) }
    }
    #endif
}

internal extension GeometryProxy {
    /// The container's corner insets for this proxy's view, or zero where they can't be read.
    func fuContainerCornerInsets(layoutDirection: LayoutDirection) -> PhysicalCornerInsets {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            return PhysicalCornerInsets(containerCornerInsets, layoutDirection: layoutDirection)
        }
        #endif
        return .zero
    }

    /// The concentric corner radii for this proxy's view, or nil where they can't be read.
    func fuConcentricCornerRadii(layoutDirection: LayoutDirection) -> PhysicalCornerRadii? {
        #if canImport(SwiftUICore, _version: 8.0.84)
        if #available(iOS 27, *) {
            return concentricCornerRadii.map { PhysicalCornerRadii($0, layoutDirection: layoutDirection) }
        }
        #endif
        return nil
    }
}
#endif
