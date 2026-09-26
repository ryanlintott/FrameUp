//
//  ContainerShapeLayoutDirectionFix.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

#if os(iOS)
/// Works around a SwiftUI bug where a container shape's corners don't follow a change of layout direction (iOS 27.1).
///
/// SwiftUI keeps a container shape's corners named as they were set (topLeading, topTrailing, and so on), and each reader interprets the names in its own layout direction. So a view whose `layoutDirection` differs from the one the shape was set in reads the rounded corners mirrored: `concentricCornerRadii`, `ConcentricRectangle`, `ContainerRelativeShape`, and the rounded-corner part of `containerCornerInsets`. The display's own corners are set in the app's direction. System UI in a corner, like the iPhone Duo's camera capsule, isn't part of the shape and is named correctly.
///
/// This modifier re-declares the container shape in the layout direction it's applied in, from radii read in the direction the shape was set. Readers inside then get the right corners. If SwiftUI is fixed, the shape it re-declares is the same as the one already there, so the modifier can be removed without changing anything.
struct ContainerShapeLayoutDirectionFix: ViewModifier {
    /// The layout direction outside, which the container shape was set in.
    let outerLayoutDirection: LayoutDirection
    /// The layout direction this modifier is applied in.
    @Environment(\.layoutDirection) private var layoutDirection
    /// The container's corner radii, named for the outer layout direction.
    @State private var outerRadii: FUCorners<CGFloat>? = nil

    func body(content: Content) -> some View {
        #if canImport(SwiftUICore, _version: 8.0.84)
        if #available(iOS 27, *) {
            /// The corners are renamed for this direction. Until the radii are read, the corners are square, so the view's identity doesn't change as they settle.
            let radii = outerRadii.map { layoutDirection == outerLayoutDirection ? $0 : $0.flippedHorizontally } ?? .init(topLeading: 0, topTrailing: 0, bottomLeading: 0, bottomTrailing: 0)
            content
                .containerShape(UnevenRoundedRectangle(cornerRadii: RectangleCornerRadii(radii), style: .continuous))
                /// The background isn't inside the shape set above, so it reads the container's own corners.
                .background {
                    GeometryReader { proxy in
                        let radii = proxy.concentricCornerRadii.map(FUCorners.init)
                        Color.clear
                            /// The radii settle over several layout passes, so every change is kept. onChange didn't work.
                            .task(id: radii) {
                                outerRadii = radii
                            }
                    }
                    .environment(\.layoutDirection, outerLayoutDirection)
                }
        } else {
            content
        }
        #else
        content
        #endif
    }
}
#endif
