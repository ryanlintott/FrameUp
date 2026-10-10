//
//  TabMenuVerticalBar.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-09.
//

import SwiftUI

#if os(iOS)
/// Where a tab menu's vertical bar is, as `tabMenuVerticalBehavior(_:)` decides.
@available(iOS 16, *)
enum TabMenuVerticalBar: Equatable, Sendable {
    /// In the system's vertical column, on this edge.
    case system(HorizontalEdge)
    /// In a custom vertical bar the menu makes for itself, on this edge. Like `toolbarVerticalEdge` for the system's bar, the edge is layout-relative, while the bar keeps its physical side in a right-to-left layout (measured on the iPhone Duo, iOS 27.1).
    case custom(HorizontalEdge)

    /// The width of the custom vertical bar: the height of the horizontal menu on an iPhone in portrait, its 50 points plus the 34 point safe area below it for the Home indicator. That matches the system's vertical column on the iPhone Duo.
    static let customBarWidth: CGFloat = 84

    var edge: HorizontalEdge {
        switch self {
        case let .system(edge), let .custom(edge): edge
        }
    }

    /// Decides where the vertical bar goes, or nil for the bottom.
    ///
    /// The system's column wins wherever the behavior allows it and there is one. Otherwise `.automatic` makes a custom bar where the vertical size class is compact. Only an iPhone has a compact height, and only in landscape. An iPad keeps a regular height even in a short, wide window, so it always keeps the menu along the bottom.
    /// - Parameters:
    ///   - behavior: Where the menu can use a vertical bar.
    ///   - systemEdge: The edge of the system's vertical column, or nil when there isn't one.
    ///   - verticalSizeClass: The vertical size class.
    ///   - interfaceOrientation: The interface orientation, which puts the custom bar on the edge away from the Dynamic Island.
    ///   - layoutDirection: The layout direction, which decides whether the custom bar's physical side is the leading or trailing edge.
    init?(
        behavior: TabMenuVerticalBehavior,
        systemEdge: HorizontalEdge?,
        verticalSizeClass: UserInterfaceSizeClass?,
        interfaceOrientation: FUInterfaceOrientation?,
        layoutDirection: LayoutDirection
    ) {
        if behavior != .disabled, let systemEdge {
            self = .system(systemEdge)
            return
        }
        guard behavior == .automatic, verticalSizeClass == .compact else { return nil }
        self = .custom(Self.customBarEdge(for: interfaceOrientation, in: layoutDirection))
    }

    /// The edge for a custom vertical bar, away from the Dynamic Island at the top of the device.
    ///
    /// These orientations are named for the device's turn, so in `.landscapeLeft` its top is on the left and the bar goes on the right. The bar keeps its physical side in a right-to-left layout, so its layout edge swaps. Anywhere else, including before the orientation is known, it goes on the right. An iPhone has a compact height only in landscape, so that's never used in practice.
    private static func customBarEdge(for orientation: FUInterfaceOrientation?, in layoutDirection: LayoutDirection) -> HorizontalEdge {
        let isOnLeft = orientation == .landscapeRight
        return isOnLeft == (layoutDirection == .leftToRight) ? .leading : .trailing
    }
}
#endif
