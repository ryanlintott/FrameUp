//
//  TabMenuVerticalBarLayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-13.
//

import SwiftUI

/// Where a vertical tab menu goes in its bar, the system's vertical toolbar or the custom bar, as padding from the window's edges.
///
/// The menu is drawn at `menuWidth`, at most `maxMenuHeight` tall, inside the window less this padding, against the bar's edge and the bottom. Where the span is shorter than `maxMenuHeight`, the items squeeze equally to fit.
@available(iOS 16, *)
struct TabMenuVerticalBarLayout: Equatable, Sendable {
    /// The system's natural item height, and the horizontal menu's height.
    static let itemHeight: CGFloat = 50
    /// The minimum tap target, below which the menu stops centring its items where the system centres its buttons.
    static let minimumItemHeight: CGFloat = 44
    /// How far the system keeps its vertical tab bar from the window's bottom edge (measured on the iPhone Duo).
    static let bottomMargin: CGFloat = 24
    /// How far the centre of the system's vertical tab bar is from the window's side: its 24 point margin plus half its 48 point width (measured on the iPhone Duo).
    static let centreInset: CGFloat = 24 + 48 / 2

    /// The edge the bar is on.
    let edge: HorizontalEdge
    let menuWidth: CGFloat
    /// The space between the screen's edge and the menu.
    let edgePadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    /// The tallest the menu grows: the items' natural height when grouped, or infinity to fill the span.
    let maxMenuHeight: CGFloat
}

@available(iOS 16, *)
extension TabMenuVerticalBarLayout {
    /// Places the menu in a bar.
    /// - Parameters:
    ///   - edge: The edge the bar is on.
    ///   - barWidth: The bar's width, from the screen's edge.
    ///   - topPadding: How far the part of the bar the menu can use is from the window's top edge.
    ///   - bottomPadding: How far the part of the bar the menu can use is from the window's bottom edge, before the grouped menu's margin.
    ///   - isGrouped: Whether the items keep their natural height at the bottom of the bar, rather than sharing its height.
    ///   - itemCount: The number of items.
    init(
        edge: HorizontalEdge,
        barWidth: CGFloat,
        topPadding: CGFloat,
        bottomPadding: CGFloat,
        isGrouped: Bool,
        itemCount: Int
    ) {
        /// Centre the items where the system centres its buttons, slightly away from the screen's edge, if the bar is wide enough to keep them tappable.
        let centredWidth = 2 * (barWidth - Self.centreInset)
        let menuWidth = centredWidth >= Self.minimumItemHeight
            ? min(barWidth, centredWidth)
            : barWidth

        self.init(
            edge: edge,
            menuWidth: menuWidth,
            edgePadding: barWidth - menuWidth,
            topPadding: topPadding,
            bottomPadding: isGrouped ? max(bottomPadding, Self.bottomMargin) : bottomPadding,
            maxMenuHeight: isGrouped ? Self.itemHeight * CGFloat(itemCount) : .infinity
        )
    }
}
