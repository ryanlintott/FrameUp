//
//  TabMenuModifier.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-09.
//

import SwiftUI

#if os(iOS)
public extension View {
    /// Places a ``TabMenu`` where the system would put its tab bar.
    ///
    /// On most screens the menu is a horizontal bar along the bottom, inset into the safe area so the content moves up to make room for it, as if the menu were placed under the view in a `VStack`.
    ///
    /// Where the system puts its bars in a vertical column instead, as on the iPhone Duo, the menu stacks its items top to bottom in that column, on the same edge as the system's tab bar, and clear of the camera, the status items and the hinge. The column is usually outside the content's safe area, so the content doesn't move; where the system names a column without a safe area for it, as in the iPhone Duo's left split window, the menu reserves it and moves the content over. This needs iOS 27.1. To keep the menu along the bottom there, use `tabMenuVerticalBehavior(.disabled)`.
    ///
    /// With `tabMenuVerticalBehavior(.automatic)` applied above the menu, an iPhone in landscape without that bar also gets a custom vertical bar against the screen's edge away from the Dynamic Island, and the content moves over to make room for it where the safe area doesn't already. On an iPad the menu always stays along the bottom. With `.disabled` the menu always runs along the bottom. See ``TabMenuVerticalBehavior``.
    ///
    /// The content, and anything else inside `tabMenuVerticalBehavior(_:)`, can read the vertical bar's edge from ``SwiftUICore/EnvironmentValues/tabMenuVerticalEdge``.
    ///
    /// Apply it to a view that fills the window, such as the root of a scene.
    ///
    /// Set how the items are drawn with `tabMenuItemStyle(_:)`, how they're spread along the bottom with `tabMenuHorizontalDistribution(_:)`, and actions for the selected item with `onTabMenuItemReselect(_:perform:)` and `onTabMenuItemDoubleTap(_:perform:)`. These can go outside this modifier, since the menu is inside it. To add an effect to the menu, put it in the item style.
    ///
    ///     ContentView()
    ///         .tabMenu(selection: $selection, items: items)
    ///         .tabMenuItemStyle(.masked { isSelected in
    ///             isSelected ? Color.accentColor : Color(.secondaryLabel)
    ///         })
    ///
    /// - Parameters:
    ///   - selection: binding for the selected tab
    ///   - items: array of `TabMenuItem`
    /// - Returns: The view with a tab menu placed for the current screen.
    @ViewBuilder
    func tabMenu<Tab: Hashable>(
        selection: Binding<Tab>,
        items: [TabMenuItem<Tab>]
    ) -> some View {
        let menu = TabMenu(selection: selection, items: items)

        if #available(iOS 16, *) {
            modifier(TabMenuModifier(menu: menu))
        } else {
            /// Before iOS 16 the menu is always along the bottom: the custom bar needs iOS 16 and the system's column iOS 27.1. The version never changes while the app runs, so this branch can't reset the content's state.
            tabMenuItemActionsDisabled()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    menu
                        .environment(\.tabMenuEdge, .bottom)
                }
        }
    }
}

/// Puts the menu along the bottom, in the system's vertical column, or in a custom vertical bar, wherever `tabMenuVerticalBehavior(_:)` chose. Before iOS 16, `tabMenu(...)` puts the menu along the bottom without it.
@available(iOS 16, *)
struct TabMenuModifier<Tab: Hashable>: ViewModifier {
    let menu: TabMenu<Tab>

    @Environment(\.tabMenuVerticalBar) private var verticalBar
    /// Where the menu goes in the system's vertical column, from the last measurement by ``SystemVerticalBarGeometryReader``. Only used while the bar is `.system`.
    @State private var systemBarGeometry: SystemVerticalBarGeometry?
    /// The safe area around the content, from the last measurement of the wrapper.
    @State private var safeAreaInsets: EdgeInsets?

    /// Where the content moves over for a vertical bar, and by how much.
    private var contentInset: (edge: HorizontalEdge, width: CGFloat)? {
        switch verticalBar {
        case let .custom(edge):
            (edge, customBarInset(beyond: edge == .leading ? safeAreaInsets?.leading : safeAreaInsets?.trailing))
        case .system:
            systemBarGeometry.flatMap { $0.reservedWidth > 0 ? ($0.edge, $0.reservedWidth) : nil }
        case nil:
            nil
        }
    }

    /// The system column's edge, where `tabMenuVerticalBehavior(_:)` chose it.
    ///
    /// `.disabled` keeps the menu along the bottom even where the system still reserves its column, such as when the app sets `toolbarVerticalBehavior(.automatic)` further out.
    private var systemEdge: HorizontalEdge? {
        guard case let .system(edge) = verticalBar else { return nil }
        return edge
    }

    func body(content: Content) -> some View {
        let verticalBar = verticalBar
        let contentInset = contentInset

        /// The content keeps the same structure in every placement, so turning the device doesn't reset its state. Only the menu moves.
        ZStack {
            content
                /// Before the inset, so the bottom menu still gets the actions.
                .tabMenuItemActionsDisabled()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    /// Like the system's tab bar, it spans the full width even across an active fold (measured on the iPhone Duo with the vertical bar turned off).
                    if verticalBar == nil {
                        menu
                            .environment(\.tabMenuEdge, .bottom)
                    }
                }
                /// Changing the edge changes an argument, not the structure, so the content keeps its state as the bar moves.
                .safeAreaInset(edge: contentInset?.edge ?? .leading, spacing: 0) {
                    if let contentInset {
                        Color.clear
                            .frame(width: contentInset.width)
                    }
                }
        }
        .overlay {
            if case let .custom(edge) = verticalBar {
                menu
                    .environment(\.tabMenuEdge, .edge(for: verticalBar))
                    .frame(width: TabMenuVerticalBar.customBarWidth)
                /// Sits against the screen's edge rather than inside the safe area on that side. In landscape an iPhone's safe area is as deep on the side away from the Dynamic Island as on the side with it, only to clear the rounded corners, and the bar stays clear of them vertically.
                    .frame(maxWidth: .infinity, alignment: edge == .leading ? .leading : .trailing)
                    .ignoresSafeArea(.container, edges: .horizontal)
            }

            /// The column has to be measured, so a screen with one shows no menu until then rather than flashing the horizontal one.
            if case .system = verticalBar, let systemBarGeometry {
                menu
                    .environment(\.tabMenuEdge, .edge(for: verticalBar))
                    .frame(width: systemBarGeometry.width, height: systemBarGeometry.height)
                    .padding(systemBarGeometry.edge == .leading ? .leading : .trailing, systemBarGeometry.horizontalEdgePadding)
                    .padding(.bottom, systemBarGeometry.bottomPadding)
                /// Spans the whole window, so the menu can sit in the column, outside the content's safe area.
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: systemBarGeometry.edge == .leading ? .bottomLeading : .bottomTrailing)
                    .ignoresSafeArea(.container)
            }
        }
        /// Measure the wrapper rather than `content`, so the menu's own insets can't affect the next measurement.
        .onGeometryChange(for: EdgeInsets.self) { proxy in
            proxy.safeAreaInsets
        } action: { newInsets in
            safeAreaInsets = newInsets
        }
        .modifier(SystemVerticalBarGeometryReader(edge: systemEdge, itemCount: menu.items.count, geometry: $systemBarGeometry))
    }

    /// How much the content moves over for the custom bar: the part of the bar's width that the safe area on that edge doesn't already cover. An iPhone with a Home button has no side safe area in landscape.
    private func customBarInset(beyond safeAreaInset: CGFloat?) -> CGFloat {
        max(0, TabMenuVerticalBar.customBarWidth - (safeAreaInset ?? 0))
    }
}

#endif
