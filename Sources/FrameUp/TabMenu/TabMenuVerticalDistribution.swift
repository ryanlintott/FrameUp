//
//  TabMenuVerticalDistribution.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-13.
//

import SwiftUI

#if os(iOS)
/// How a vertical tab menu, placed with `tabMenu(selection:items:)`, spreads its items along its bar.
///
/// A horizontal menu ignores this. See ``TabMenuHorizontalDistribution``.
@available(iOS 16, *)
public enum TabMenuVerticalDistribution: Hashable, Sendable {
    /// Each bar's own spread: `.grouped` in the system's vertical toolbar, like the system's tab bar, and `.equal` in the custom vertical bar.
    case automatic
    /// Items share the bar's full height equally, each centred in its share. In the system's vertical toolbar, that's the part of it clear of the camera and the hinge.
    case equal
    /// Items keep the system's 50 point height, stacked at the bottom of the bar, 24 points above the screen's bottom edge or above the camera. When there isn't room, they shrink equally to fit.
    case grouped
}
#endif

#if os(iOS)
@available(iOS 16, *)
public extension View {
    /// Sets how the items are spread along the vertical bar of tab menus in this view.
    ///
    /// It can go outside `tabMenu(selection:items:)`, since the menu is inside it. A horizontal menu ignores this.
    ///
    ///     ContentView()
    ///         .tabMenu(selection: $selection, items: items)
    ///         .tabMenuVerticalDistribution(.equal)
    ///
    /// - Parameter distribution: How the items are spread. Default is `.automatic`, grouped at the bottom of the system's vertical toolbar and equal in the custom bar.
    /// - Returns: A view whose vertical tab menus spread their items this way.
    func tabMenuVerticalDistribution(_ distribution: TabMenuVerticalDistribution) -> some View {
        environment(\.tabMenuVerticalDistribution, distribution)
    }
}
#endif
