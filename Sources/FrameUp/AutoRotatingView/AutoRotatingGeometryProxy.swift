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
/// SwiftUI doesn't turn the container's corner insets with a rotation, so inside an `AutoRotatingView` its own `containerCornerInsets` and `containerCornerOffset` describe the unrotated container. Use these values instead.
///
///     AutoRotatingView([.portrait]) { geometry in
///         Content()
///             .padding(.top, geometry.containerCornerInsets.topTrailing.height)
///     }
///
/// The proxy only holds values that don't rotate properly. Everything else is correct in a `GeometryReader` inside the content: its size and safe area insets match the rotated content frame, SwiftUI maps reserved regions through the rotation, and `AutoRotatingView` sets a container shape that makes `concentricCornerRadii`, `ConcentricRectangle` and `ContainerRelativeShape` correct inside it.
///
/// The corner insets describe one frame, the whole content. Corner insets for smaller views inside the content aren't covered yet: SwiftUI's rule for resolving them isn't a plain overlap with the corners, and hasn't been worked out.
public struct AutoRotatingGeometryProxy: Equatable, Sendable {
    /// The container's corner insets, moved to the content corners they sit on.
    let cornerInsets: FUCornerInsets

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
}
#endif
