//
//  TabMenu.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2020-12-31.
//

import SwiftUI

#if os(iOS)
/// Customizable tab menu bar view designed to mimic the style of the default tab menu bar.
///
/// A ``TabMenuItemStyle`` set with `tabMenuItemStyle(_:)` draws each item. The default, ``TabMenuItemStyle/automatic``, masks a color with each item's icon and title. Actions for reselecting and double tapping the selected item are set with `onTabMenuItemReselect(_:perform:)` and `onTabMenuItemDoubleTap(_:perform:)`, and the spread of the items with `tabMenuHorizontalDistribution(_:)`. All of these can go on the menu or on any view above it.
///
///     let items = [
///        TabMenuItem("Info", systemImage: "globe", tab: 0),
///        TabMenuItem("Favourites", systemImage: "star", tab: 1),
///        TabMenuItem("Categories", systemImage: "bookmark", tab: 2),
///        TabMenuItem("About", systemImage: "books.vertical", tab: 3)
///     ]
///
///     TabMenu(selection: $selection, items: items)
///         .tabMenuItemStyle(.masked { isSelected in
///             isSelected ? Color.accentColor : Color(.secondaryLabel)
///         })
///         .onTabMenuItemReselect("Reselect") {
///             print("TabMenu item \(selection) reselected")
///         }
///         .onTabMenuItemDoubleTap("Double Tap") {
///             print("TabMenu item \(selection) doubletapped")
///         }
///
/// Placed by hand, the menu is a horizontal bar. Use `tabMenu(selection:items:)` to place it where the system would put its tab bar, which can be a vertical bar.
@available(iOS 16, *)
public struct TabMenu<Tab: Hashable>: View {
    /// The screen edge the menu is placed against. Only `tabMenu(selection:items:)` sets it, so a menu placed by hand sees nil and stays horizontal.
    @Environment(\.tabMenuEdge) private var edge
    @Environment(\.tabMenuItemStyle) private var environmentItemStyle
    @Environment(\.tabMenuHorizontalDistribution) private var horizontalDistribution
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.tabMenuItemReselectAction) private var environmentReselect
    @Environment(\.tabMenuItemDoubleTapAction) private var environmentDoubleTap

    @Binding var selection: Tab
    let items: [TabMenuItem<Tab>]

    /// Set only by the deprecated initialiser that takes a masked view and actions, in place of the environment's style and actions. Remove with TabMenu+Deprecated.swift.
    var itemStyleOverride: (any TabMenuItemStyle)? = nil
    var reselectOverride: TabMenuItemAction? = nil
    var doubleTapOverride: TabMenuItemAction? = nil

    /// The overrides take precedence over the environment. When they're removed, read the environment directly. Remove with TabMenu+Deprecated.swift.
    private var itemStyle: any TabMenuItemStyle { itemStyleOverride ?? environmentItemStyle }
    private var onReselect: TabMenuItemAction? { reselectOverride ?? environmentReselect }
    private var onDoubleTap: TabMenuItemAction? { doubleTapOverride ?? environmentDoubleTap }

    /// Creates a customized tab menu view
    /// - Parameters:
    ///   - selection: binding for the selected tab
    ///   - items: array of `TabMenuItem`
    public init(selection: Binding<Tab>, items: [TabMenuItem<Tab>]) {
        self._selection = selection
        self.items = items
    }

    /// The direction the items are laid out in.
    private var axis: Axis {
        switch edge {
        case .leading, .trailing: .vertical
        case .top, .bottom, nil: .horizontal
        }
    }

    public var body: some View {
        switch axis {
        case .horizontal:
            let (maxItemWidth, itemSpacing) = horizontalDistribution.itemLayout(for: horizontalSizeClass)
            HStack(spacing: itemSpacing) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    itemView(item, at: index) { styledItem in
                        styledItem
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: maxItemWidth)
                    }
                }
            }
            .reportingTabMenuItemsFrame()
            /// Centres the items when they don't fill the width.
            .frame(maxWidth: .infinity)
            .padding(.bottom, 2)
            .padding(.horizontal, 1)
            .frame(height: 50)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Tab bar"))
        case .vertical:
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    /// The items share the menu's height, each centred in its share. `tabMenu(selection:items:)` sets the height from `tabMenuVerticalDistribution(_:)`: the bar's full height, or a group at its bottom.
                    itemView(item, at: index) { styledItem in
                        styledItem
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal, 4)
                    }
                }
            }
            .reportingTabMenuItemsFrame()
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Tab bar"))
        }
    }

    /// Draws an item with the item style, opening the style's type.
    private func styledItem<S: TabMenuItemStyle>(_ style: S, configuration: TabMenuItemStyleConfiguration) -> AnyView {
        AnyView(style.makeBody(configuration: configuration))
    }

    /// An item drawn with the item style in its cell, with the selection, taps and accessibility around it, so a style can't break them.
    /// - Parameters:
    ///   - item: The item to draw.
    ///   - index: The item's position in the menu, for VoiceOver.
    ///   - cell: Places the styled item in its cell, which takes taps.
    func itemView<Cell: View>(_ item: TabMenuItem<Tab>, at index: Int, @ViewBuilder cell: (AnyView) -> Cell) -> some View {
        let isSelected = selection == item.tab
        let configuration = TabMenuItemStyleConfiguration(label: item.label, isSelected: isSelected, edge: edge)

        return cell(styledItem(itemStyle, configuration: configuration))
            /// The whole cell takes taps, so a style that draws less than the cell is still easy to hit.
            .contentShape(Rectangle())
            .onTapGesture {
                if selection != item.tab {
                    selection = item.tab
                }
            }
            .overlay {
                if isSelected {
                    let tapArea = Color.clear.contentShape(Rectangle())
                    if let onDoubleTap {
                        tapArea
                            .onTapGesture(count: 2) {
                                onDoubleTap.action()
                            }
                            .onTapGesture {
                                onReselect?.action()
                            }
                    } else {
                        tapArea
                            .onTapGesture {
                                onReselect?.action()
                            }
                    }
                }
            }
            /// Merges whatever the style draws, including the label, which names the item.
            .accessibilityElement(children: .combine)
            /// The selected item offers its actions to VoiceOver by name.
            .accessibilityActions {
                if let onReselect, isSelected {
                    Button(action: onReselect.action) { onReselect.name }
                }
                if let onDoubleTap, isSelected {
                    Button(action: onDoubleTap.action) { onDoubleTap.name }
                }
            }
            .accessibilityHint(Text("Tab\n\(index + 1) of \(items.count)"))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
#endif
