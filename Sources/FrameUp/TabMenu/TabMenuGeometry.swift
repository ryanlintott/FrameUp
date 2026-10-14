//
//  TabMenuGeometry.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-11.
//

import SwiftUI

#if os(iOS)
/// Where the menu placed with `tabMenu(selection:items:)` is drawn, for content that lines up with its items.
///
/// Read it from ``SwiftUICore/EnvironmentValues/tabMenuGeometry`` in the content of `tabMenu(selection:items:)`. Its frames are in the ``SwiftUICore/CoordinateSpace/tabMenu`` coordinate space, so compare them with a frame measured in the same space:
///
///     GeometryReader { proxy in
///         let frame = proxy.frame(in: .tabMenu)
///         if let geometry = tabMenuGeometry {
///             /// How far the menu's items are below the middle of this view.
///             let offset = geometry.itemsFrame.midY - frame.midY
///         }
///     }
///
/// For which edge a vertical bar is on, read ``SwiftUICore/EnvironmentValues/tabMenuVerticalEdge``, which is set before anything is measured.
public struct TabMenuGeometry: Equatable, Sendable {
    /// The menu's items, from the first item's edge to the last's. Along the bottom they're spread as set by `tabMenuHorizontalDistribution(_:)`. In a vertical bar they're centred slightly away from the screen's edge, where the system centres its buttons, and run the bar's height or stack at its bottom, as set by `tabMenuVerticalDistribution(_:)`.
    ///
    /// A vertical bar is outside the content's safe area, so content that fills the bar can ignore the safe area on that edge rather than measure it.
    public let itemsFrame: CGRect
}

/// The frame of a menu's items in the ``SwiftUICore/CoordinateSpace/tabMenu`` space, reported by ``TabMenu`` for `tabMenu(selection:items:)`.
struct TabMenuItemsFrameKey: PreferenceKey {
    static let defaultValue: CGRect? = nil
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        /// SwiftUI can pass in the default value from views that don't set this key, which would otherwise replace the measured frame.
        value = nextValue() ?? value
    }
}

extension View {
    /// Reports this view's frame as the menu's items.
    func reportingTabMenuItemsFrame() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: TabMenuItemsFrameKey.self, value: proxy.frame(in: .tabMenu))
            }
        }
    }
}

/// The name of the coordinate space that `tabMenu(selection:items:)` sets up around its content and menu.
struct TabMenuCoordinateSpaceName: Hashable {}

public extension CoordinateSpace {
    /// The coordinate space around the content and menu of `tabMenu(selection:items:)`, in which ``TabMenuGeometry`` gives its frames.
    static var tabMenu: CoordinateSpace {
        .named(TabMenuCoordinateSpaceName())
    }
}
#endif
