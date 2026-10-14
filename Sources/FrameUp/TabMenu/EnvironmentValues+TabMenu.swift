//
//  EnvironmentValues+TabMenu.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-09.
//

import SwiftUI

#if os(iOS)
@available(iOS 16, *)
private struct TabMenuEdgeKey: EnvironmentKey {
    static let defaultValue: Edge? = nil
}

@available(iOS 16, *)
private struct TabMenuItemStyleKey: EnvironmentKey {
    /// Computed, so the style needn't be `Sendable`.
    static var defaultValue: any TabMenuItemStyle { AutomaticTabMenuItemStyle() }
}

@available(iOS 16, *)
private struct TabMenuItemIconIsResizableKey: EnvironmentKey {
    static let defaultValue = false
}

@available(iOS 16, *)
private struct TabMenuHorizontalDistributionKey: EnvironmentKey {
    static let defaultValue: TabMenuHorizontalDistribution = .automatic
}

@available(iOS 16, *)
private struct TabMenuVerticalDistributionKey: EnvironmentKey {
    static let defaultValue: TabMenuVerticalDistribution = .automatic
}

@available(iOS 16, *)
private struct TabMenuItemReselectActionKey: EnvironmentKey {
    /// Computed, so the action needn't be `Sendable`.
    static var defaultValue: TabMenuItemAction? { nil }
}

@available(iOS 16, *)
private struct TabMenuItemDoubleTapActionKey: EnvironmentKey {
    /// Computed, so the action needn't be `Sendable`.
    static var defaultValue: TabMenuItemAction? { nil }
}

@available(iOS 16, *)
private struct TabMenuVerticalBehaviorKey: EnvironmentKey {
    static let defaultValue: TabMenuVerticalBehavior = .system
}

@available(iOS 16, *)
private struct TabMenuInterfaceOrientationKey: EnvironmentKey {
    static let defaultValue: FUInterfaceOrientation? = nil
}

@available(iOS 16, *)
private struct TabMenuGeometryKey: EnvironmentKey {
    static let defaultValue: TabMenuGeometry? = nil
}

@available(iOS 16, *)
public extension EnvironmentValues {
    /// The edge of the vertical bar that holds tab menus placed in this view, or nil when they run along the bottom.
    ///
    /// Set by `tabMenuVerticalBehavior(_:)` for everything inside it, as `toolbarVerticalBehavior(_:)` sets `toolbarVerticalEdge`, from the same decision that places the menu, so it always matches where the menu is. Without it, this matches `toolbarVerticalEdge`, and is nil where that isn't available. Like `toolbarVerticalEdge`, it's layout-relative, while the bar keeps its physical side in a right-to-left layout. It can't be set directly.
    var tabMenuVerticalEdge: HorizontalEdge? {
        tabMenuVerticalBar?.edge
    }

    /// Where the menu placed with `tabMenu(selection:items:)` is drawn, or nil until it has been measured.
    ///
    /// Set by `tabMenu(selection:items:)` for its content. The frames are in the ``SwiftUICore/CoordinateSpace/tabMenu`` coordinate space. It can't be set directly.
    internal(set) var tabMenuGeometry: TabMenuGeometry? {
        get { self[TabMenuGeometryKey.self] }
        set { self[TabMenuGeometryKey.self] = newValue }
    }
}

@available(iOS 16, *)
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

    /// The interface orientation, which places the custom vertical bar. Set by `tabMenuVerticalBehavior(_:)`, which tracks it.
    var tabMenuInterfaceOrientation: FUInterfaceOrientation? {
        get { self[TabMenuInterfaceOrientationKey.self] }
        set { self[TabMenuInterfaceOrientationKey.self] = newValue }
    }

    /// The vertical bar that holds tab menus placed in this view, or nil for the bottom.
    var tabMenuVerticalBar: TabMenuVerticalBar? {
        TabMenuVerticalBar(
            behavior: tabMenuVerticalBehavior,
            systemEdge: toolbarVerticalEdgeIfAvailable,
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
