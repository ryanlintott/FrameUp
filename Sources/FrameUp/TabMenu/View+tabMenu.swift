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
        /// The content keeps the same structure on both axes, so turning the device doesn't reset its state. Only the menu moves.
        content
            .overlay {
                GeometryReader { proxy in
                    let newLayout = TabMenuLayout(
                        edge: toolbarVerticalEdge,
                        proxy: proxy,
                        itemCount: menu.items.count
                    )
                    Color.clear
                        .onAppear {
                            update(to: newLayout)
                        }
                        .onChange(of: newLayout) {
                            update(to: newLayout)
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isHorizontal {
                    menu
                }
            }
    }

    /// Mid-turn, SwiftUI can report the new edge a layout pass before the safe area moves to it (measured on the iPhone Duo). Keeping the last layout through that pass stops the horizontal bar flashing up.
    private func update(to newLayout: TabMenuLayout) {
        guard newLayout != .unmeasured else { return }
        layout = newLayout
    }
}

@available(iOS 27.1, *)
fileprivate enum TabMenuLayout: Equatable {
    /// The column hasn't been measured, or is mid-change.
    case unmeasured
    case horizontal
    case vertical(VerticalTabMenuGeometry)

    /// Where the menu goes, measured from the content it's attached to.
    ///
    /// All values are in the content's own layout-relative coordinates, which is the space `toolbarVerticalEdge`, the safe area insets and the reserved regions (with their default `.mirrors` behaviour) share.
    init(edge: HorizontalEdge?, proxy: GeometryProxy, itemCount: Int) {
        guard let edge, itemCount > 0 else {
            self = .horizontal
            return
        }

        let insets = proxy.safeAreaInsets
        let size = proxy.size
        let width = edge == .leading ? insets.leading : insets.trailing
        /// The environment names a column the safe area doesn't have yet.
        guard width > 0 else {
            self = .unmeasured
            return
        }

        /// The column runs the window's full height, beside the content.
        let columnMinX = edge == .leading ? -width : size.width
        let columnMaxX = columnMinX + width
        let windowTop = -insets.top
        let windowBottom = size.height + insets.bottom

        /// The camera and status items, and the hinge whether or not it's active, since it's physically there whenever the screen is open. Ignoring its active state also keeps the menu still when the hinge goes from fully to partly open.
        let reservedRegions = proxy.reservedRegions(kind: .occlusion)
            + proxy.reservedRegions(kind: .division, options: .includeInactive)

        /// The column's free spans, top to bottom, once every region crossing it is taken out.
        var freeSpans: [ClosedRange<CGFloat>] = [windowTop...(windowBottom - VerticalTabMenuGeometry.systemBarMargin)]
        for region in reservedRegions where region.frame.maxX > columnMinX && region.frame.minX < columnMaxX {
            freeSpans = freeSpans.flatMap { span -> [ClosedRange<CGFloat>] in
                var remaining: [ClosedRange<CGFloat>] = []
                if region.frame.minY > span.lowerBound {
                    remaining.append(span.lowerBound...min(span.upperBound, region.frame.minY))
                }
                if region.frame.maxY < span.upperBound {
                    remaining.append(max(span.lowerBound, region.frame.maxY)...span.upperBound)
                }
                return remaining
            }
        }

        /// The menu sits at the bottom of the column, like the system's tab bar, so use the lowest span with room for the items. If there's none, or the column is too narrow to tap, the menu goes along the bottom.
        let minimumMenuHeight = CGFloat(itemCount) * VerticalTabMenuGeometry.minimumItemHeight
        guard
            width >= VerticalTabMenuGeometry.minimumItemHeight,
            let span = freeSpans.last(where: { $0.upperBound - $0.lowerBound >= minimumMenuHeight })
        else {
            self = .horizontal
            return
        }

        let spanHeight = span.upperBound - span.lowerBound
        let itemHeight = min(VerticalTabMenuGeometry.itemHeight, spanHeight / CGFloat(itemCount))

        /// Centre the items where the system centres its buttons, if the column is wide enough to keep them tappable.
        let centredWidth = 2 * (width - VerticalTabMenuGeometry.centreInset)
        let menuWidth = centredWidth >= VerticalTabMenuGeometry.minimumItemHeight ? min(width, centredWidth) : width

        self = .vertical(
            VerticalTabMenuGeometry(
                width: menuWidth,
                horizontalEdgePadding: width - menuWidth,
                itemHeight: itemHeight,
                height: itemHeight * CGFloat(itemCount),
                bottomPadding: windowBottom - span.upperBound
            )
        )
    }
}

/// Where a vertical tab menu goes in the system's vertical bar.
@available(iOS 27.1, *)
fileprivate struct VerticalTabMenuGeometry: Equatable {
    /// The system's natural item height, and the horizontal menu's height.
    static let itemHeight: CGFloat = 50
    /// The smallest item height before the menu gives up on the column. The minimum tap target.
    static let minimumItemHeight: CGFloat = 44
    /// How far the system keeps its vertical tab bar from the window's bottom edge and from the side it's on (measured on the iPhone Duo).
    static let systemBarMargin: CGFloat = 24
    /// How far the centre of the system's vertical tab bar is from the window's side: its margin plus half its 48 point width.
    static let centreInset: CGFloat = 24 + 48 / 2

    /// The menu's width.
    let width: CGFloat
    /// The distance from the menu to the window's side, so its items line up with the system's.
    let horizontalEdgePadding: CGFloat
    /// The height of each item.
    let itemHeight: CGFloat
    /// The menu's height.
    let height: CGFloat
    /// The distance from the menu's bottom to the window's bottom edge.
    let bottomPadding: CGFloat
}
#endif
#endif
