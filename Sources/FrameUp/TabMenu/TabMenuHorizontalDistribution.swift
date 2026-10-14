//
//  TabMenuHorizontalDistribution.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

#if os(iOS)
/// How a horizontal ``TabMenu`` spreads its items across its width.
///
/// A vertical menu, in the system's vertical bar on the iPhone Duo or a custom vertical bar, ignores this. See ``TabMenuVerticalDistribution``.
@available(iOS 16, *)
public enum TabMenuHorizontalDistribution: Hashable, Sendable {
    /// Follows the horizontal size class, like `UITabBar`'s automatic item positioning: `.equal` where the width is compact, as on an iPhone in portrait, and grouped where it's regular, as on an iPad.
    case automatic
    /// Items share the menu's full width equally, like the iPhone tab bar in iOS 15–18.
    case equal
    /// Items are at most `maxItemWidth` wide, `spacing` apart, and centred as a group. When there isn't room, they shrink equally to fit.
    case grouped(maxItemWidth: CGFloat, spacing: CGFloat = 0)

    /// The grouped spread `.automatic` uses where the width is regular.
    static let automaticGrouped = TabMenuHorizontalDistribution.grouped(maxItemWidth: 90, spacing: 8)

    /// The spread to draw with, `.equal` or `.grouped`, with `.automatic` resolved for the horizontal size class.
    func resolved(for horizontalSizeClass: UserInterfaceSizeClass?) -> TabMenuHorizontalDistribution {
        guard self == .automatic else { return self }
        return horizontalSizeClass == .regular ? Self.automaticGrouped : .equal
    }
}
#endif

#if os(iOS)
@available(iOS 16, *)
public extension View {
    /// Sets how the items are spread across the width of horizontal tab menus in this view.
    ///
    /// It can go outside `tabMenu(selection:items:)`, since the menu is inside it. A vertical menu ignores this, and uses `tabMenuVerticalDistribution(_:)`.
    ///
    ///     ContentView()
    ///         .tabMenu(selection: $selection, items: items)
    ///         .tabMenuHorizontalDistribution(.grouped(maxItemWidth: 90, spacing: 8))
    ///
    /// - Parameter distribution: How the items are spread. Default is `.automatic`, where they share the full width when it's compact and are grouped when it's regular.
    /// - Returns: A view whose horizontal tab menus spread their items this way.
    func tabMenuHorizontalDistribution(_ distribution: TabMenuHorizontalDistribution) -> some View {
        environment(\.tabMenuHorizontalDistribution, distribution)
    }
}
#endif
