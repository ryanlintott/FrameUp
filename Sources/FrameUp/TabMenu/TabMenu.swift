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
public struct TabMenu<Tab: Hashable>: View {
    /// The screen edge the menu is placed against. Only `tabMenu(selection:items:)` sets it, so a menu placed by hand sees nil and stays horizontal.
    @Environment(\.tabMenuEdge) private var edge
    @Environment(\.tabMenuItemStyle) private var itemStyle
    @Environment(\.tabMenuHorizontalDistribution) private var horizontalDistribution
    @Environment(\.tabMenuItemReselectAction) private var onReselect
    @Environment(\.tabMenuItemDoubleTapAction) private var onDoubleTap

    @Binding var selection: Tab
    let items: [TabMenuItem<Tab>]

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
            HStack(spacing: itemSpacing) {
                ForEach(items) { item in
                    itemView(item) { styledItem in
                        styledItem
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: maxItemWidth)
                    }
                }
            }
            /// Centres the items when they don't fill the width.
            .frame(maxWidth: .infinity)
            .padding(.bottom, 2)
            .padding(.horizontal, 1)
            .frame(height: 50)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Tab bar"))
        case .vertical:
            VStack(spacing: 0) {
                ForEach(items) { item in
                    /// The items share the menu's height, each centred in its share. The placement sets the height: the whole custom bar, or the stack that fits the system's column.
                    itemView(item) { styledItem in
                        styledItem
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.horizontal, 4)
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Tab bar"))
        }
    }

    /// The widest a horizontal item can be, including its padding.
    var maxItemWidth: CGFloat {
        switch horizontalDistribution {
        case .equal: .infinity
        case let .grouped(maxItemWidth, _): maxItemWidth
        }
    }

    /// The space between horizontal items.
    var itemSpacing: CGFloat {
        switch horizontalDistribution {
        case .equal: 0
        case let .grouped(_, spacing): spacing
        }
    }

    /// Draws an item with the item style, opening the style's type.
    private func styledItem<S: TabMenuItemStyle>(_ style: S, configuration: TabMenuItemStyleConfiguration) -> AnyView {
        AnyView(style.makeBody(configuration: configuration))
    }

    /// An item drawn with the item style in its cell, with the selection, taps and accessibility around it, so a style can't break them.
    /// - Parameters:
    ///   - item: The item to draw.
    ///   - cell: Places the styled item in its cell, which takes taps.
    func itemView<Cell: View>(_ item: TabMenuItem<Tab>, @ViewBuilder cell: (AnyView) -> Cell) -> some View {
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
            .overlay(
                Group {
                    if isSelected {
                        if let onDoubleTap {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture(count: 2) {
                                    onDoubleTap.action()
                                }
                                .onTapGesture {
                                    onReselect?.action()
                                }
                        } else {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onReselect?.action()
                                }
                        }
                    }
                }
            )
            .background(
                ZStack {
                    if let onReselect, isSelected {
                        Color.clear.accessibilityAction(named: onReselect.name, onReselect.action)
                    }
                    if let onDoubleTap, isSelected {
                        Color.clear.accessibilityAction(named: onDoubleTap.name, onDoubleTap.action)
                    }
                }
            )
            /// Merges whatever the style draws, including the label, which names the item, with the named actions.
            .accessibilityElement(children: .combine)
            .accessibilityHint(tabVoiceOverHint(tabItem: item))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    func tabVoiceOverHint(tabItem: TabMenuItem<Tab>) -> Text {
        guard let tabIndex = items.firstIndex(where: { $0.tab == tabItem.tab }) else {
            return Text("")
        }

        return Text("Tab\n\(tabIndex + 1) of \(items.count)")
    }
}
#endif
