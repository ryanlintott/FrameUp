//
//  EnvironmentValues+TabMenu.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-09.
//

import SwiftUI

#if os(iOS)
private struct TabMenuEdgeKey: EnvironmentKey {
    static let defaultValue: Edge? = nil
}

private struct TabMenuItemStyleKey: EnvironmentKey {
    /// Computed, so the style needn't be `Sendable`.
    static var defaultValue: any TabMenuItemStyle { AutomaticTabMenuItemStyle() }
}

private struct TabMenuItemIconIsResizableKey: EnvironmentKey {
    static let defaultValue = false
}

private struct TabMenuHorizontalDistributionKey: EnvironmentKey {
    static let defaultValue: TabMenuHorizontalDistribution = .automatic
}

private struct TabMenuVerticalDistributionKey: EnvironmentKey {
    static let defaultValue: TabMenuVerticalDistribution = .automatic
}

private struct TabMenuItemReselectActionKey: EnvironmentKey {
    /// Computed, so the action needn't be `Sendable`.
    static var defaultValue: TabMenuItemAction? { nil }
}

private struct TabMenuItemDoubleTapActionKey: EnvironmentKey {
    /// Computed, so the action needn't be `Sendable`.
    static var defaultValue: TabMenuItemAction? { nil }
}

private struct TabMenuVerticalBehaviorKey: EnvironmentKey {
    static let defaultValue: TabMenuVerticalBehavior = .system
}

private struct TabMenuVerticalEdgeSettingKey: EnvironmentKey {
    static let defaultValue: TabMenuVerticalEdge = .automatic
}

private struct TabMenuPlacedVerticalBarKey: EnvironmentKey {
    static let defaultValue: TabMenuPlacedVerticalBar? = nil
}

/// The vertical bar a tab menu was placed in, or nil for the bottom, wrapped so the environment can tell it apart from not having been placed.
struct TabMenuPlacedVerticalBar: Hashable, Sendable {
    let bar: TabMenuVerticalBar?
}

private struct TabMenuInterfaceOrientationKey: EnvironmentKey {
    static let defaultValue: FUInterfaceOrientation? = nil
}

private struct TabMenuGeometryKey: EnvironmentKey {
    static let defaultValue: TabMenuGeometry? = nil
}

public extension EnvironmentValues {
    /// The edge of the vertical bar that holds tab menus placed in this view, or nil when they run along the bottom.
    ///
    /// Set by `tabMenuVerticalBehavior(_:)` for everything inside it, as `toolbarVerticalBehavior(_:)` sets `toolbarVerticalEdge`, from the same decision that places the menu, so it always matches where the menu is. Inside `tabMenu(selection:items:)` it's the menu's own placement, which follows the safe area as the interface turns. Without either, this matches `toolbarVerticalEdge`, and is nil where that isn't available. Like `toolbarVerticalEdge`, it's layout-relative, while the bar keeps its physical side in a right-to-left layout.
    ///
    /// Choose the edge with `tabMenuVerticalEdge(_:)`. This reports where the bar ended up.
    var tabMenuVerticalEdge: HorizontalEdge? {
        if let tabMenuPlacedVerticalBar {
            return tabMenuPlacedVerticalBar.bar?.edge
        }
        return tabMenuVerticalBar(safeAreaInsets: nil)?.edge
    }

    /// Where the menu placed with `tabMenu(selection:items:)` is drawn, or nil until it has been measured.
    ///
    /// Set by `tabMenu(selection:items:)` for its content. The frames are in the ``SwiftUICore/CoordinateSpace/tabMenu`` coordinate space. It can't be set directly.
    internal(set) var tabMenuGeometry: TabMenuGeometry? {
        get { self[TabMenuGeometryKey.self] }
        set { self[TabMenuGeometryKey.self] = newValue }
    }
}

extension EnvironmentValues {
    /// The screen edge a ``TabMenu`` is placed against, which also decides the direction it lays out its items. Only `tabMenu(selection:items:)` sets it, on the menu it places, so a menu placed by hand sees nil and stays horizontal.
    var tabMenuEdge: Edge? {
        get { self[TabMenuEdgeKey.self] }
        set { self[TabMenuEdgeKey.self] = newValue }
    }

    /// The style that draws the items of a ``TabMenu``. Set by `tabMenuItemStyle(_:)`.
    var tabMenuItemStyle: any TabMenuItemStyle {
        get { self[TabMenuItemStyleKey.self] }
        set { self[TabMenuItemStyleKey.self] = newValue }
    }

    /// Whether a `TabMenuItemIcon` holding an image makes it resizable. Set by styles that draw the icon at a fixed size.
    var tabMenuItemIconIsResizable: Bool {
        get { self[TabMenuItemIconIsResizableKey.self] }
        set { self[TabMenuItemIconIsResizableKey.self] = newValue }
    }

    /// How a horizontal ``TabMenu`` spreads its items. Set by `tabMenuHorizontalDistribution(_:)`.
    var tabMenuHorizontalDistribution: TabMenuHorizontalDistribution {
        get { self[TabMenuHorizontalDistributionKey.self] }
        set { self[TabMenuHorizontalDistributionKey.self] = newValue }
    }

    /// True when a horizontal ``TabMenu`` takes all the height it's given rather than the system's 50 points. Set by `tabMenuFillsHeight(_:)`.
    var tabMenuFillsHeight: Bool {
        get { self[TabMenuFillsHeightKey.self] }
        set { self[TabMenuFillsHeightKey.self] = newValue }
    }

    /// How a vertical tab menu spreads its items along its bar. Set by `tabMenuVerticalDistribution(_:)`.
    var tabMenuVerticalDistribution: TabMenuVerticalDistribution {
        get { self[TabMenuVerticalDistributionKey.self] }
        set { self[TabMenuVerticalDistributionKey.self] = newValue }
    }

    /// The action a ``TabMenu`` runs when its selected item is tapped again. Set by `onTabMenuItemReselect(_:perform:)`.
    var tabMenuItemReselectAction: TabMenuItemAction? {
        get { self[TabMenuItemReselectActionKey.self] }
        set { self[TabMenuItemReselectActionKey.self] = newValue }
    }

    /// The action a ``TabMenu`` runs when its selected item is tapped twice. Set by `onTabMenuItemDoubleTap(_:perform:)`.
    var tabMenuItemDoubleTapAction: TabMenuItemAction? {
        get { self[TabMenuItemDoubleTapActionKey.self] }
        set { self[TabMenuItemDoubleTapActionKey.self] = newValue }
    }

    /// Where tab menus placed in this view can stack their items in a vertical bar. Set by `tabMenuVerticalBehavior(_:)`. Without it, `.system`, so menus follow the system's vertical toolbar.
    var tabMenuVerticalBehavior: TabMenuVerticalBehavior {
        get { self[TabMenuVerticalBehaviorKey.self] }
        set { self[TabMenuVerticalBehaviorKey.self] = newValue }
    }

    /// The edge set for the vertical bar. Set by `tabMenuVerticalEdge(_:)`.
    var tabMenuVerticalEdgeSetting: TabMenuVerticalEdge {
        get { self[TabMenuVerticalEdgeSettingKey.self] }
        set { self[TabMenuVerticalEdgeSettingKey.self] = newValue }
    }

    /// The vertical bar `tabMenu(selection:items:)` placed its menu in. Set by `tabMenu(selection:items:)` for its content.
    var tabMenuPlacedVerticalBar: TabMenuPlacedVerticalBar? {
        get { self[TabMenuPlacedVerticalBarKey.self] }
        set { self[TabMenuPlacedVerticalBarKey.self] = newValue }
    }

    /// The interface orientation, which places the custom vertical bar. Set by `tabMenuVerticalBehavior(_:)`, which tracks it.
    var tabMenuInterfaceOrientation: FUInterfaceOrientation? {
        get { self[TabMenuInterfaceOrientationKey.self] }
        set { self[TabMenuInterfaceOrientationKey.self] = newValue }
    }

    /// The vertical bar that holds tab menus placed in this view, or nil for the bottom.
    /// - Parameter safeAreaInsets: The safe area around the menu's content, measured in the same update, or nil if it isn't known.
    func tabMenuVerticalBar(safeAreaInsets: EdgeInsets?) -> TabMenuVerticalBar? {
        TabMenuVerticalBar(
            behavior: tabMenuVerticalBehavior,
            edge: tabMenuVerticalEdgeSetting,
            systemEdge: toolbarVerticalEdgeIfAvailable,
            safeAreaInsets: safeAreaInsets,
            verticalSizeClass: verticalSizeClass,
            interfaceOrientation: tabMenuInterfaceOrientation,
            layoutDirection: layoutDirection
        )
    }

    /// The edge of the system's vertical toolbar, or nil when there isn't one or `toolbarVerticalEdge` isn't available.
    var toolbarVerticalEdgeIfAvailable: HorizontalEdge? {
        /// `toolbarVerticalEdge` arrived in the iOS 27.1 SDK, whose SwiftUICore is version 8.0.85 (8.0.84 in the iOS 27.0 SDK). Both SDKs ship the same Swift compiler, so a compiler version check can't tell them apart.
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            return toolbarVerticalEdge
        }
        #endif
        return nil
    }
}
#endif
