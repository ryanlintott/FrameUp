//
//  TabMenuVerticalBar.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-09.
//

import SwiftUI

#if os(iOS)
/// Where a tab menu's vertical bar is, as `tabMenuVerticalBehavior(_:)` decides.
enum TabMenuVerticalBar: Hashable, Sendable {
    /// In the system's vertical toolbar, on this edge.
    case system(HorizontalEdge)
    /// In a custom vertical bar the menu makes for itself, on this edge. Like `toolbarVerticalEdge` for the system's bar, the edge is layout-relative, while the bar keeps its physical side in a right-to-left layout (measured on the iPhone Duo, iOS 27.1).
    case custom(HorizontalEdge)

    /// The width of the custom vertical bar, the same as the system's vertical toolbar on the iPhone Duo. That's also the height of the horizontal menu on an iPhone in portrait, its 50 points plus the 34 point safe area below it for the Home indicator.
    static let customBarWidth = SystemToolbarVerticalGeometry.defaultWidth

    var edge: HorizontalEdge {
        switch self {
        case let .system(edge), let .custom(edge): edge
        }
    }

    /// The screen edge a menu in this bar is against. Without a bar, `tabMenu(selection:items:)` puts it against the bottom.
    var menuEdge: Edge {
        switch edge {
        case .leading: .leading
        case .trailing: .trailing
        }
    }

    /// The system's vertical toolbar's edge when the menu is in it, or nil.
    ///
    /// `.disabled` keeps the menu along the bottom even where the system still reserves its toolbar, such as when the app sets `toolbarVerticalBehavior(.automatic)` further out, so this is nil there.
    var systemEdge: HorizontalEdge? {
        guard case let .system(edge) = self else { return nil }
        return edge
    }

    /// Decides where the vertical bar goes, or nil for the bottom.
    ///
    /// The system's vertical toolbar wins wherever the behavior allows it and there is one, unless `edge` puts the menu on the other side, where it makes a custom bar on that edge instead. Otherwise `.automatic` makes a custom bar where the vertical size class is compact, on `edge` or away from the Dynamic Island. Only an iPhone has a compact height, and only in landscape. An iPad keeps a regular height even in a short, wide window, so it always keeps the menu along the bottom.
    /// - Parameters:
    ///   - behavior: Where the menu can use a vertical bar.
    ///   - edge: The edge set for the vertical bar.
    ///   - systemEdge: The edge of the system's vertical toolbar, or nil when there isn't one.
    ///   - safeAreaInsets: The safe area around the menu's content, measured in the same update, which corrects the system's toolbar edge as the interface turns. See ``systemEdge(_:safeAreaInsets:)``.
    ///   - verticalSizeClass: The vertical size class.
    ///   - interfaceOrientation: The interface orientation, which puts the custom bar on the edge away from the Dynamic Island.
    ///   - layoutDirection: The layout direction, which decides whether the custom bar's physical side is the leading or trailing edge.
    init?(
        behavior: TabMenuVerticalBehavior,
        edge: TabMenuVerticalEdge = .automatic,
        systemEdge: HorizontalEdge?,
        safeAreaInsets: EdgeInsets? = nil,
        verticalSizeClass: UserInterfaceSizeClass?,
        interfaceOrientation: FUInterfaceOrientation?,
        layoutDirection: LayoutDirection
    ) {
        if behavior != .disabled, let systemEdge = Self.systemEdge(systemEdge, safeAreaInsets: safeAreaInsets) {
            if let edge = edge.horizontalEdge, edge != systemEdge {
                self = .custom(edge)
            } else {
                self = .system(systemEdge)
            }
            return
        }
        guard behavior == .automatic, verticalSizeClass == .compact else { return nil }
        self = .custom(edge.horizontalEdge ?? Self.customBarEdge(for: interfaceOrientation, in: layoutDirection))
    }

    /// The edge of the system's vertical toolbar, taken from the safe area where that shows it.
    ///
    /// As the interface turns, the safe area changes an update before `toolbarVerticalEdge` does (measured on the iPhone Duo, iOS 27.1). The system's turn keeps that first update on screen until it ends, so a menu placed from `toolbarVerticalEdge` alone sits in the wrong place for the whole turn: on the wrong side when the toolbar changes sides, as between portrait and the landscape with the camera on the left on the outer screen, or in a toolbar that's gone or not there yet, as between portrait and landscape on the inner screen.
    ///
    /// The safe area shows the toolbar as it is on the Duo:
    /// - Where `toolbarVerticalEdge` names a toolbar and one side's safe area is deeper, the toolbar is on that side. Only the toolbar gives the Duo a safe area on a side.
    /// - Where it names none, a toolbar has just arrived if there's no top safe area, one side's is exactly the toolbar's width and the other side's is zero. The toolbar holds the status bar, so there's no top safe area beside it. Other iPhones have even sides in landscape, or none.
    /// - Where it names a toolbar but there's a top safe area and the sides are even, the toolbar has just gone, as the status bar is back along the top. The Duo's left split window names a toolbar with no safe area for it, but has no top safe area either, so it keeps its toolbar.
    ///
    /// An app that hides the status bar on the inner screen in portrait has no top safe area there, so its menu can still lag a turn into portrait.
    /// - Parameters:
    ///   - edge: The edge from `toolbarVerticalEdge`, or nil when there's no toolbar.
    ///   - safeAreaInsets: The safe area measured in the same update, or nil if it isn't known.
    /// - Returns: The toolbar's edge, or nil when there's no toolbar.
    static func systemEdge(_ edge: HorizontalEdge?, safeAreaInsets: EdgeInsets?) -> HorizontalEdge? {
        guard let safeAreaInsets else { return edge }
        let deeperEdge: HorizontalEdge = safeAreaInsets.leading > safeAreaInsets.trailing ? .leading : .trailing
        guard safeAreaInsets.leading == safeAreaInsets.trailing else {
            if edge != nil {
                return deeperEdge
            }
            let isArrivingToolbar = safeAreaInsets.top == 0
                && min(safeAreaInsets.leading, safeAreaInsets.trailing) == 0
                && max(safeAreaInsets.leading, safeAreaInsets.trailing) == SystemToolbarVerticalGeometry.defaultWidth
            return isArrivingToolbar ? deeperEdge : nil
        }
        if edge != nil, safeAreaInsets.top > 0 {
            return nil
        }
        return edge
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
