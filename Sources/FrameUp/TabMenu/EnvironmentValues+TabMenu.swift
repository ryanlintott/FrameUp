//
//  EnvironmentValues+TabMenu.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-09.
//

import SwiftUI

#if os(iOS)
private struct TabMenuAxisKey: EnvironmentKey {
    static let defaultValue: Axis = .horizontal
}

private struct TabMenuVerticalBehaviorKey: EnvironmentKey {
    static let defaultValue: TabMenuVerticalBehavior = .system
}

private struct TabMenuInterfaceOrientationKey: EnvironmentKey {
    static let defaultValue: FUInterfaceOrientation? = nil
}

public extension EnvironmentValues {
    /// The edge of the vertical bar that holds tab menus placed in this view, or nil when they run along the bottom.
    ///
    /// Set by `tabMenuVerticalBehavior(_:)` for everything inside it, as `toolbarVerticalBehavior(_:)` sets `toolbarVerticalEdge`. Without it, this matches `toolbarVerticalEdge`, and is nil where that isn't available. Like `toolbarVerticalEdge`, it's layout-relative, while the bar keeps its physical side in a right-to-left layout. It can't be set directly.
    var tabMenuVerticalEdge: HorizontalEdge? {
        /// Vertical bars need iOS 16, so before that the menu always runs along the bottom.
        if #available(iOS 16, *) {
            tabMenuVerticalBar?.edge
        } else {
            nil
        }
    }
}

extension EnvironmentValues {
    /// The direction a ``TabMenu`` lays out its items. Only `tabMenu(selection:items:isShowingName:horizontalDistribution:maskedView:onReselect:onDoubleTap:)` sets it, on the menu it places in a vertical bar, so a menu placed any other way stays horizontal.
    var tabMenuAxis: Axis {
        get { self[TabMenuAxisKey.self] }
        set { self[TabMenuAxisKey.self] = newValue }
    }

    /// Where tab menus placed in this view can stack their items in a vertical bar. Set by `tabMenuVerticalBehavior(_:)`. Without it, `.system`, so menus follow the system's vertical column.
    @available(iOS 16, *)
    var tabMenuVerticalBehavior: TabMenuVerticalBehavior {
        get { self[TabMenuVerticalBehaviorKey.self] }
        set { self[TabMenuVerticalBehaviorKey.self] = newValue }
    }

    /// The interface orientation, which places the custom vertical bar. Set by `tabMenuVerticalBehavior(_:)`, which tracks it.
    @available(iOS 16, *)
    var tabMenuInterfaceOrientation: FUInterfaceOrientation? {
        get { self[TabMenuInterfaceOrientationKey.self] }
        set { self[TabMenuInterfaceOrientationKey.self] = newValue }
    }

    /// The vertical bar that holds tab menus placed in this view, or nil for the bottom.
    @available(iOS 16, *)
    var tabMenuVerticalBar: TabMenuVerticalBar? {
        TabMenuVerticalBar(
            behavior: tabMenuVerticalBehavior,
            systemEdge: toolbarVerticalEdgeIfAvailable,
            verticalSizeClass: verticalSizeClass,
            interfaceOrientation: tabMenuInterfaceOrientation,
            layoutDirection: layoutDirection
        )
    }

    /// The edge of the system's vertical column, or nil when there isn't one or `toolbarVerticalEdge` isn't available.
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
