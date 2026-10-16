//
//  TabMenuVerticalEdge.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-15.
//

import SwiftUI

#if os(iOS)
/// The edge a tab menu placed with `tabMenu(selection:items:)` uses for its vertical bar.
///
/// Set it with `tabMenuVerticalEdge(_:)`. Read where the bar ended up from ``SwiftUICore/EnvironmentValues/tabMenuVerticalEdge``.
public enum TabMenuVerticalEdge: Hashable, Sendable {
    /// The system's vertical toolbar wherever there is one, and otherwise a custom bar on the edge away from the Dynamic Island. This is the default.
    case automatic
    /// The leading edge. Where the system's vertical toolbar is on the trailing edge, the menu makes a custom bar on the leading edge instead.
    case leading
    /// The trailing edge. Where the system's vertical toolbar is on the leading edge, the menu makes a custom bar on the trailing edge instead.
    case trailing

    /// The edge this sets, or nil for `.automatic`.
    var horizontalEdge: HorizontalEdge? {
        switch self {
        case .automatic: nil
        case .leading: .leading
        case .trailing: .trailing
        }
    }
}

public extension View {
    /// Sets the edge tab menus placed with `tabMenu(selection:items:)` inside this view use for their vertical bar.
    ///
    /// It only chooses the edge. Whether the menu is vertical at all is up to `tabMenuVerticalBehavior(_:)`. Where the system's vertical toolbar is on the other edge, such as on the iPhone Duo's outer screen in the landscape with the camera on the left, the menu makes a custom vertical bar on this edge instead. The system still reserves its toolbar for the camera and status bar, so the content keeps its safe area there.
    ///
    /// Like ``SwiftUICore/EnvironmentValues/tabMenuVerticalEdge``, the edge is layout-relative.
    ///
    ///     ContentView()
    ///         .tabMenu(selection: $selection, items: items)
    ///         .tabMenuVerticalBehavior(.automatic)
    ///         .tabMenuVerticalEdge(.trailing)
    ///
    /// - Parameter edge: The edge for the vertical bar. Default is `.automatic`.
    /// - Returns: A view whose tab menus put their vertical bar on this edge.
    func tabMenuVerticalEdge(_ edge: TabMenuVerticalEdge) -> some View {
        environment(\.tabMenuVerticalEdgeSetting, edge)
    }
}
#endif
