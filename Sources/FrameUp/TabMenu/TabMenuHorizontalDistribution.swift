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
/// A vertical menu, in the system's vertical bar on the iPhone Duo or a custom vertical bar, always stacks its items and ignores this.
public enum TabMenuHorizontalDistribution: Hashable, Sendable {
    /// Items share the menu's full width equally, like the iPhone tab bar in iOS 15–18.
    case equal
    /// Items are at most `maxItemWidth` wide, `spacing` apart, and centred as a group. When there isn't room, they shrink equally to fit.
    case grouped(maxItemWidth: CGFloat, spacing: CGFloat = 0)
}
#endif

#if os(iOS)
public extension View {
    /// Sets how the items are spread across the width of horizontal tab menus in this view.
    ///
    /// It can go outside `tabMenu(selection:items:)`, since the menu is inside it. A vertical menu always stacks its items and ignores this.
    ///
    ///     ContentView()
    ///         .tabMenu(selection: $selection, items: items)
    ///         .tabMenuHorizontalDistribution(.grouped(maxItemWidth: 90, spacing: 8))
    ///
    /// - Parameter distribution: How the items are spread. Default is `.equal`, where they share the full width.
    /// - Returns: A view whose horizontal tab menus spread their items this way.
    func tabMenuHorizontalDistribution(_ distribution: TabMenuHorizontalDistribution) -> some View {
        environment(\.tabMenuHorizontalDistribution, distribution)
    }
}
#endif
