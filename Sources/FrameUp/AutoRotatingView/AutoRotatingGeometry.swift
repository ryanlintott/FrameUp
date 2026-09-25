//
//  AutoRotatingGeometry.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

#if os(iOS)
/// The container geometry of an `AutoRotatingView`'s content, in the content's own rotated coordinate space.
///
/// SwiftUI doesn't turn the container's corner insets with a rotation, so inside an `AutoRotatingView` its own `containerCornerInsets` and `containerCornerOffset` describe the unrotated container. Use these values instead.
///
///     AutoRotatingView([.portrait]) { geometry in
///         Content()
///             .padding(.top, geometry.containerCornerInsets.topTrailing.height)
///     }
///
/// Reserved regions and concentric corner radii don't need this. SwiftUI already maps reserved regions through the rotation, and `AutoRotatingView` sets a container shape that makes `concentricCornerRadii`, `ConcentricRectangle` and `ContainerRelativeShape` correct inside it.
///
/// Like a `GeometryProxy`, the values describe one frame, here the whole content. Corner insets for smaller views inside the content aren't covered yet: SwiftUI's rule for resolving them isn't a plain overlap with the corners, and hasn't been worked out.
public struct AutoRotatingGeometry: Equatable, Sendable {
    /// The size of the content frame, including any safe area.
    public let size: CGSize
    /// The safe area insets of the content, re-created inside the rotation.
    public let safeAreaInsets: EdgeInsets
    /// The container's corner insets, moved to the content corners they sit on.
    let cornerInsets: FUCorners<CGSize>

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
    var fuContainerCornerInsets: FUCorners<CGSize> {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            let insets = containerCornerInsets
            return FUCorners(topLeading: insets.topLeading, topTrailing: insets.topTrailing, bottomLeading: insets.bottomLeading, bottomTrailing: insets.bottomTrailing)
        }
        #endif
        return .zero
    }
}
#endif
