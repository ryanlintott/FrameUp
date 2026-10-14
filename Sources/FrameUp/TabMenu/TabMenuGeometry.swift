//
//  TabMenuGeometry.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-11.
//

import SwiftUI

#if os(iOS)
/// Where the menu placed with `tabMenu(selection:items:)` is drawn, for content that lines up with its items.
///
/// Read it from ``SwiftUICore/EnvironmentValues/tabMenuGeometry`` in the content of `tabMenu(selection:items:)`. Its frames are in the ``SwiftUICore/CoordinateSpace/tabMenu`` coordinate space, so compare them with a frame measured in the same space:
///
///     GeometryReader { proxy in
///         let frame = proxy.frame(in: .tabMenu)
///         if let geometry = tabMenuGeometry {
///             /// How far the menu's items are below the middle of this view.
///             let offset = geometry.itemsFrame.midY - frame.midY
///         }
///     }
///
/// For which edge a vertical bar is on, read ``SwiftUICore/EnvironmentValues/tabMenuVerticalEdge``, which is set before anything is measured.
public struct TabMenuGeometry: Equatable, Sendable {
    /// The bar that holds the menu, including any part of it under the safe area: the custom vertical bar, the system's vertical toolbar, or the horizontal bar and the space below it to the screen's bottom edge.
    public let barFrame: CGRect
    /// The menu's items. Along the bottom they fill the bar's width. In a vertical bar they're centred slightly away from the screen's edge, where the system centres its buttons, and run the bar's height or stack at its bottom, as set by `tabMenuVerticalDistribution(_:)`.
    public let itemsFrame: CGRect
}

/// The name of the coordinate space that `tabMenu(selection:items:)` sets up around its content and menu.
struct TabMenuCoordinateSpaceName: Hashable {}

public extension CoordinateSpace {
    /// The coordinate space around the content and menu of `tabMenu(selection:items:)`, in which ``TabMenuGeometry`` gives its frames.
    static var tabMenu: CoordinateSpace {
        .named(TabMenuCoordinateSpaceName())
    }
}
#endif
