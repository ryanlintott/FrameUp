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
    /// Where the system puts its bars in a vertical toolbar instead, as on the iPhone Duo, the menu stacks its items top to bottom in that toolbar, on the same edge as the system's tab bar, and clear of the camera, the status items and the hinge. The toolbar is usually outside the content's safe area, so the content doesn't move; where the system names a vertical toolbar without a safe area for it, as in the iPhone Duo's left split window, the menu reserves it and moves the content over. This needs iOS 27.1. To keep the menu along the bottom there, use `tabMenuVerticalBehavior(.disabled)`.
    ///
    /// With `tabMenuVerticalBehavior(.automatic)` applied above the menu, an iPhone in landscape without that bar also gets a custom vertical bar against the screen's edge away from the Dynamic Island, and the content moves over to make room for it where the safe area doesn't already. On an iPad the menu always stays along the bottom. With `.disabled` the menu always runs along the bottom. See ``TabMenuVerticalBehavior``.
    ///
    /// The content, and anything else inside `tabMenuVerticalBehavior(_:)`, can read the vertical bar's edge from ``SwiftUICore/EnvironmentValues/tabMenuVerticalEdge``. The content can also read exactly where it's drawn from ``SwiftUICore/EnvironmentValues/tabMenuGeometry``.
    ///
    /// Apply it to a view that fills the window, such as the root of a scene.
    ///
    /// Set how the items are drawn with `tabMenuItemStyle(_:)`, how they're spread along the bottom with `tabMenuHorizontalDistribution(_:)` and along a vertical bar with `tabMenuVerticalDistribution(_:)`, and actions for the selected item with `onTabMenuItemReselect(_:perform:)` and `onTabMenuItemDoubleTap(_:perform:)`. These can go outside this modifier, since the menu is inside it. To add an effect to the menu, put it in the item style.
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
    func tabMenu<Tab: Hashable>(
        selection: Binding<Tab>,
        items: [TabMenuItem<Tab>]
    ) -> some View {
        modifier(TabMenuModifier(menu: TabMenu(selection: selection, items: items)))
    }
}

/// Puts the menu along the bottom, in the system's vertical toolbar, or in a custom vertical bar, wherever `tabMenuVerticalBehavior(_:)` chose.
struct TabMenuModifier<Tab: Hashable>: ViewModifier {
    let menu: TabMenu<Tab>

    @Environment(\.tabMenuVerticalBar) private var verticalBar
    @Environment(\.tabMenuVerticalDistribution) private var verticalDistribution
    /// Where the menu goes in the system's vertical toolbar, from the last measurement by ``SystemToolbarVerticalGeometryReader``. Only used while the bar is `.system`.
    @State private var systemToolbarVerticalGeometry: SystemToolbarVerticalGeometry?
    /// The safe area around the content, from the last measurement of the wrapper.
    @State private var safeAreaInsets: EdgeInsets?
    /// The frame of the menu's items in the ``SwiftUICore/CoordinateSpace/tabMenu`` space, for each bar that has drawn the menu. Each bar keeps its own, because a menu that's leaving can report once more after the new bar's menu has (measured on the iPhone 18 Pro, iOS 27.0, rotating into the custom vertical bar).
    @State private var measuredItemsFrames: [TabMenuVerticalBar?: CGRect] = [:]

    /// Where the menu goes in a vertical bar, or nil along the bottom, and in the system's vertical toolbar until it has been measured.
    private var verticalBarLayout: TabMenuVerticalBarLayout? {
        switch verticalBar {
        case nil:
            return nil
        case let .custom(edge):
            /// The part of the bar's width that the safe area on that edge doesn't already cover. An iPhone with a Home button has no side safe area in landscape.
            let safeAreaInset = (edge == .leading ? safeAreaInsets?.leading : safeAreaInsets?.trailing) ?? 0
            /// Sits against the screen's edge rather than inside the safe area on that side, and runs the screen's full height. In landscape an iPhone's safe area is as deep on the side away from the Dynamic Island as on the side with it, only to clear the rounded corners.
            return TabMenuVerticalBarLayout(
                edge: edge,
                barWidth: TabMenuVerticalBar.customBarWidth,
                topPadding: 0,
                bottomPadding: 0,
                isGrouped: verticalDistribution.isGrouped(in: .custom(edge)),
                itemCount: menu.items.count,
                contentInset: max(0, TabMenuVerticalBar.customBarWidth - safeAreaInset)
            )
        case .system:
            return systemToolbarVerticalGeometry.map {
                TabMenuVerticalBarLayout(
                    edge: $0.edge,
                    barWidth: $0.width,
                    topPadding: $0.topPadding,
                    bottomPadding: $0.bottomPadding,
                    isGrouped: verticalDistribution.isGrouped(in: .system($0.edge)),
                    itemCount: menu.items.count,
                    contentInset: $0.reservedWidth
                )
            }
        }
    }

    /// Where the menu is drawn, for the content, once its items have been measured.
    private var geometry: TabMenuGeometry? {
        measuredItemsFrames[verticalBar].map { TabMenuGeometry(itemsFrame: $0) }
    }

    /// Records the frame of a menu's items.
    ///
    /// Each bar draws its own menu, so the bar when the body runs is the one this menu is in.
    private func measuringItems(_ menu: some View) -> some View {
        let verticalBar = verticalBar
        return menu
            /// ``TabMenu`` reports its items rather than its whole frame, which runs the screen's width along the bottom. A menu that's leaving reports nil, which is ignored.
            .onPreferenceChangeMainActor(TabMenuItemsFrameKey.self) { newFrame in
                if let newFrame {
                    measuredItemsFrames[verticalBar] = newFrame
                }
            }
    }

    func body(content: Content) -> some View {
        let verticalBar = verticalBar
        let verticalBarLayout = verticalBarLayout

        /// The content keeps the same structure in every placement, so turning the device doesn't reset its state. Only the menu moves.
        ZStack {
            content
                .environment(\.tabMenuGeometry, geometry)
                /// Before the inset, so the bottom menu still gets the actions.
                .tabMenuItemActionsDisabled()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    /// Like the system's tab bar, it spans the full width even across an active fold (measured on the iPhone Duo with the vertical bar turned off).
                    if verticalBar == nil {
                        measuringItems(menu)
                            .environment(\.tabMenuEdge, .bottom)
                    }
                }
                /// Changing the edge changes an argument, not the structure, so the content keeps its state as the bar moves.
                .safeAreaInset(edge: verticalBarLayout?.edge ?? .leading, spacing: 0) {
                    if let verticalBarLayout, verticalBarLayout.contentInset > 0 {
                        Color.clear
                            .frame(width: verticalBarLayout.contentInset)
                    }
                }
        }
        .overlay {
            /// The system's vertical toolbar has to be measured, so a screen with one shows no menu until then rather than flashing the horizontal one.
            if let verticalBarLayout {
                measuringItems(
                    menu
                        .environment(\.tabMenuEdge, verticalBar?.menuEdge ?? .bottom)
                        .frame(width: verticalBarLayout.menuWidth)
                        .frame(maxHeight: verticalBarLayout.maxMenuHeight)
                )
                .padding(verticalBarLayout.edge == .leading ? .leading : .trailing, verticalBarLayout.edgePadding)
                .padding(.top, verticalBarLayout.topPadding)
                .padding(.bottom, verticalBarLayout.bottomPadding)
                /// Spans the whole window, so the menu can sit in its bar, outside the content's safe area, and stays put when the keyboard appears.
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: verticalBarLayout.edge == .leading ? .bottomLeading : .bottomTrailing)
                .ignoresSafeArea()
            }
        }
        .coordinateSpace(name: TabMenuCoordinateSpaceName())
        /// Measure the wrapper rather than `content`, so the menu's own insets can't affect the next measurement.
        .background {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: TabMenuSafeAreaInsetsKey.self, value: proxy.safeAreaInsets)
            }
        }
        .onPreferenceChangeMainActor(TabMenuSafeAreaInsetsKey.self) { newInsets in
            if let newInsets {
                safeAreaInsets = newInsets
            }
        }
        .modifier(SystemToolbarVerticalGeometryReader(edge: verticalBar?.systemEdge, geometry: $systemToolbarVerticalGeometry))
    }
}
/// The safe area around the content of `tabMenu(selection:items:)`.
struct TabMenuSafeAreaInsetsKey: PreferenceKey {
    static let defaultValue: EdgeInsets? = nil
    static func reduce(value: inout EdgeInsets?, nextValue: () -> EdgeInsets?) {
        /// SwiftUI can pass in the default value from views that don't set this key, which would otherwise replace the measured insets.
        value = nextValue() ?? value
    }
}
#endif
