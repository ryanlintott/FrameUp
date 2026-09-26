//
//  AutoRotatingGeometryProxy.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

#if os(iOS)
/// Container geometry that SwiftUI doesn't turn with an `AutoRotatingView`'s content, turned into the content's own rotated coordinate space.
///
/// SwiftUI doesn't turn the container's corners with a rotation, so inside an `AutoRotatingView` its own `containerCornerInsets`, `containerCornerOffset` and `concentricCornerRadii` describe the unrotated container. Use these values instead.
///
///     AutoRotatingView([.portrait]) { geometry in
///         Content()
///             .padding(.top, geometry.containerCornerInsets.topTrailing.height)
///     }
///
/// The proxy only holds values that don't rotate properly. Everything else is correct in a `GeometryReader` inside the content: its size and safe area insets match the rotated content frame, and SwiftUI maps reserved regions through the rotation.
///
/// Shapes that SwiftUI resolves from the container, such as `ConcentricRectangle` and `ContainerRelativeShape`, also see the unrotated container. On a screen whose corners all have the same radius they still look right. Where the corners differ, as on the iPhone Duo's outer screen, draw the content's corners from ``concentricCornerRadii`` instead. `AutoRotatingView` doesn't set a container shape of its own, since SwiftUI would then resolve every view inside against the content frame rather than the container, which changes the shape of style backgrounds and overlays even when nothing is turned.
///
/// The values describe one frame, the whole content. Values for smaller views inside the content aren't covered yet: SwiftUI's rule for resolving them isn't a plain overlap with the corners, and hasn't been worked out.
public struct AutoRotatingGeometryProxy: Equatable, Sendable {
    /// The container's corner insets, moved to the content corners they sit on.
    let cornerInsets: FUCornerInsets
    /// The container's corner radii, moved to the content corners they sit on, or nil where they can't be read.
    let cornerRadii: FUCornerRadii?

    #if compiler(>=6.2)
    /// The container's corner insets for each corner of the content, turned with the content.
    ///
    /// These can include system UI in a corner, such as the camera capsule on an iPhone Duo, as well as rounded display or window corners. Use them as padding or offsets to keep content clear of the corners, as you would SwiftUI's `GeometryProxy.containerCornerInsets` outside a rotation.
    @available(iOS 26, *)
    public var containerCornerInsets: RectangleCornerInsets {
        RectangleCornerInsets(
            topLeading: cornerInsets.topLeading,
            topTrailing: cornerInsets.topTrailing,
            bottomLeading: cornerInsets.bottomLeading,
            bottomTrailing: cornerInsets.bottomTrailing
        )
    }
    #endif

    #if canImport(SwiftUICore, _version: 8.0.84)
    /// The container's corner radii for each corner of the content, turned with the content, or nil if SwiftUI doesn't report any.
    ///
    /// Use these to round the content's corners to follow the display's, as you would SwiftUI's `GeometryProxy.concentricCornerRadii` outside a rotation.
    ///
    ///     AutoRotatingView { geometry in
    ///         Content()
    ///             .background {
    ///                 UnevenRoundedRectangle(cornerRadii: geometry.concentricCornerRadii ?? .init(), style: .continuous)
    ///                     .fill(.blue)
    ///             }
    ///     }
    @available(iOS 27, *)
    public var concentricCornerRadii: RectangleCornerRadii? {
        cornerRadii.map(RectangleCornerRadii.init)
    }
    #endif
}

internal extension GeometryProxy {
    /// The container's corner insets for this proxy's view, or zero where they can't be read.
    var fuContainerCornerInsets: FUCornerInsets {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            let insets = containerCornerInsets
            return FUCornerInsets(topLeading: insets.topLeading, topTrailing: insets.topTrailing, bottomLeading: insets.bottomLeading, bottomTrailing: insets.bottomTrailing)
        }
        #endif
        return .zero
    }

    /// The concentric corner radii for this proxy's view, or nil where they can't be read.
    var fuConcentricCornerRadii: FUCornerRadii? {
        #if canImport(SwiftUICore, _version: 8.0.84)
        if #available(iOS 27, *) {
            return concentricCornerRadii.map(FUCornerRadii.init)
        }
        #endif
        return nil
    }
}
#endif
