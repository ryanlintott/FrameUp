//
//  View+tabMenu.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

#if os(iOS)
public extension View {
    /// Places a ``TabMenu`` where the system would put its tab bar.
    ///
    /// On most screens the menu is a horizontal bar along the bottom, inset into the safe area so the content moves up to make room for it, as if the menu were placed under the view in a `VStack`.
    ///
    /// Where the system puts its bars in a vertical column instead, as on the iPhone Duo, the menu stacks its items top to bottom in that column, on the same edge as the system's tab bar, and clear of the camera, the status items and the hinge. The column is already outside the content's safe area, so the content doesn't move. This needs iOS 27.1. An app that turns the vertical bar off with `toolbarVerticalBehavior(.disabled)` gets the horizontal bar along the bottom.
    ///
    /// Apply it to a view that fills the window, such as the root of a scene.
    ///
    ///     ContentView()
    ///         .tabMenu(selection: $selection, items: items) { isSelected in
    ///             isSelected ? Color.accentColor : Color(.secondaryLabel)
    ///         }
    ///
    /// - Parameters:
    ///   - selection: binding for the selected tab
    ///   - items: array of `TabMenuItem`
    ///   - isShowingName: A Boolean value that indicates whether the name should be shown. Default is true if any tab menu item has a non-nil name.
    ///   - itemPositioning: How the items are spread across the width of the horizontal menu. Default is `.fill`, where they share the full width. The vertical menu always stacks them.
    ///   - maskedView: A view that will be shown, masked by the icon and text. A simple color or a more complex view can be provided. A Boolean value with the selected state is passed in so that the view can change accordingly.
    ///   - onReselect: A named action to run when a selected tab is reselected.
    ///   - onDoubleTap: A named action to run when a selected tab is tapped twice.
    /// - Returns: The view with a tab menu placed for the current screen.
    func tabMenu<Tab: Hashable, MaskedView: View>(
        selection: Binding<Tab>,
        items: [TabMenuItem<Tab>],
        isShowingName: Bool? = nil,
        itemPositioning: TabMenuItemPositioning = .fill,
        maskedView: @escaping (Bool) -> MaskedView,
        onReselect: (() -> NamedAction)? = nil,
        onDoubleTap: (() -> NamedAction)? = nil
    ) -> some View {
        modifier(
            TabMenuPlacementModifier(
                menu: TabMenu(
                    selection: selection,
                    items: items,
                    isShowingName: isShowingName,
                    itemPositioning: itemPositioning,
                    maskedView: maskedView,
                    onReselect: onReselect,
                    onDoubleTap: onDoubleTap
                )
            )
        )
    }
}

fileprivate struct TabMenuPlacementModifier<Tab: Hashable, MaskedView: View>: ViewModifier {
    let menu: TabMenu<Tab, MaskedView>

    func body(content: Content) -> some View {
        /// `toolbarVerticalEdge` and `reservedRegions` arrived in the iOS 27.1 SDK, whose SwiftUICore is version 8.0.85 (8.0.84 in the iOS 27.0 SDK). Both SDKs ship the same Swift compiler, so a compiler version check can't tell them apart.
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            content
                .modifier(AdaptiveTabMenuModifier(menu: menu))
        } else {
            content
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    menu
                }
        }
        #else
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                menu
            }
        #endif
    }
}

#if canImport(SwiftUICore, _version: 8.0.85)
/// Puts the menu in the system's vertical bar when there is one, and along the bottom otherwise.
@available(iOS 27.1, *)
fileprivate struct AdaptiveTabMenuModifier<Tab: Hashable, MaskedView: View>: ViewModifier {
    let menu: TabMenu<Tab, MaskedView>

    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
    /// Where the menu goes, from the last measurement of the content.
    @State private var layout: TabMenuLayout = .unmeasured

    /// The environment says whether there's a vertical bar straight away, but the column has to be measured, so a screen with a vertical bar shows no menu until then rather than flashing the horizontal one.
    private var isHorizontal: Bool {
        toolbarVerticalEdge == nil || layout == .horizontal
    }

    private var geometry: VerticalTabMenuGeometry? {
        guard toolbarVerticalEdge != nil, case let .vertical(geometry) = layout else { return nil }
        return geometry
    }

    func body(content: Content) -> some View {
        let edge = toolbarVerticalEdge
        let itemCount = menu.items.count

        /// The content keeps the same structure on both axes, so turning the device doesn't reset its state. Only the menu moves.
        ZStack {
            content
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    /// Like the system's tab bar, it spans the full width even across an active fold (measured on the iPhone Duo with the vertical bar turned off).
                    if isHorizontal {
                        menu
                    }
                }
        }
        .overlay {
            if let geometry, let toolbarVerticalEdge {
                menu
                    .vertical(itemHeight: geometry.itemHeight)
                    .frame(width: geometry.width, height: geometry.height)
                    .padding(toolbarVerticalEdge == .leading ? .leading : .trailing, geometry.horizontalEdgePadding)
                    .padding(.bottom, geometry.bottomPadding)
                /// Spans the whole window, so the menu can sit in the column, outside the content's safe area.
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: toolbarVerticalEdge == .leading ? .bottomLeading : .bottomTrailing)
                    .ignoresSafeArea(.container)
            }
        }
        /// Measure the wrapper rather than `content`, so the horizontal menu's own safe-area inset cannot affect the next placement calculation.
        .onGeometryChange(for: TabMenuLayout.self) { proxy in
            /// A region's frame already includes its margins: SwiftUI reports the same frame and margins as UIKit's `reservedRegions(kind:)`, whose frame is documented to include them (measured on the iPhone Duo: a 40 point hinge frame with 20 point margins, centred on the fold).
            let occlusionFrames = proxy.reservedRegions(kind: .occlusion).map(\.frame)
            let divisionFrames = proxy.reservedRegions(kind: .division, options: .includeInactive).map(\.frame)
            return TabMenuLayout(
                edge: edge,
                contentSize: proxy.size,
                safeAreaInsets: proxy.safeAreaInsets,
                reservedFrames: occlusionFrames + divisionFrames,
                itemCount: itemCount
            )
        } action: {
            update(to: $0)
        }
    }

    /// Mid-turn, SwiftUI can report the new edge a layout pass before the safe area moves to it (measured on the iPhone Duo). Keeping the last layout through that pass stops the horizontal bar flashing up.
    private func update(to newLayout: TabMenuLayout) {
        guard newLayout != .unmeasured else { return }
        layout = newLayout
    }
}
#endif
#endif
