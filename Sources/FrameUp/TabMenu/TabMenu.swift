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
/// Extra functions available for `onReselect` and `onDoubleTap`
///
/// Images or views and name provied are used to mask another provided view which is often a color.
///
///     let items = [
///        TabMenuItem(image: Image(systemName: "globe"), name: "Info", tab: 0),
///        TabMenuItem(image: Image(systemName: "star"), name: "Favourites", tab: 1),
///        TabMenuItem(image: Image(systemName: "bookmark"), name: "Categories", tab: 2),
///        TabMenuItem(image: Image(systemName: "books.vertical"), name: "About", tab: 3)
///     ]
///
///     TabMenu(selection: $selection, items: items) { isSelected in
///        Group {
///            if isSelected {
///                Color.accentColor
///            } else {
///                Color(.secondaryLabel)
///            }
///        }
///     } onReselect: {
///         NamedAction("Reselect") {
///             print("TabMenu item \(selection) reselected")
///         }
///     } onDoubleTap: {
///         NamedAction("Double Tap") {
///             print("TabMenu item \(selection) doubletapped")
///         }
///     }
///
public struct TabMenu<Tab: Hashable, Content: View>: View {
    @Binding var selection: Tab
    let items: [TabMenuItem<Tab>]
    let isShowingName: Bool
    let itemPositioning: TabMenuItemPositioning
    let maskedView: (Bool) -> Content
    let onReselect: NamedAction?
    let onDoubleTap: NamedAction?
    
    /// Creates a customized tab menu view
    /// - Parameters:
    ///   - selection: binding for the selected tab
    ///   - items: array of `TabMenuItem`
    ///   - isShowingName: A Boolean value that indicates whether the name should be shown. Default is true if any tab menu item has a non-nil name.
    ///   - itemPositioning: How the items are spread across the menu's width. Default is `.fill`, where they share the full width.
    ///   - onReselect: A named action to run when a selected tab is reselected.
    ///   - onDoubleTap: A named action to run when a selected tab is tapped twice.
    ///   - maskedView: A view that will be shown, masked by the icon and text. A simple color or a more complex view can be provided. A Boolean value with the selected state is passed in so that the view can change accordingly.
    public init(selection: Binding<Tab>, items: [TabMenuItem<Tab>], isShowingName: Bool? = nil, itemPositioning: TabMenuItemPositioning = .fill, maskedView: @escaping (Bool) -> Content, onReselect: (() -> NamedAction)? = nil, onDoubleTap: (() -> NamedAction)? = nil) {
        self._selection = selection
        self.items = items
        self.isShowingName = isShowingName ?? (items.first(where: { $0.name != nil }) != nil)
        self.itemPositioning = itemPositioning
        self.maskedView = maskedView
        self.onReselect = onReselect?() ?? nil
        self.onDoubleTap = onDoubleTap?() ?? nil
    }
    
    /// The direction the items are laid out in. Vertical only when `tabMenu(selection:items:isShowingName:itemPositioning:maskedView:onReselect:onDoubleTap:)` places the menu in the system's vertical bar.
    var axis: Axis = .horizontal
    /// The height of each item when the axis is vertical.
    var verticalItemHeight: CGFloat = 50

    /// A copy of this menu that stacks its items top to bottom, each one `itemHeight` tall and as wide as the menu.
    func vertical(itemHeight: CGFloat) -> Self {
        var menu = self
        menu.axis = .vertical
        menu.verticalItemHeight = itemHeight
        return menu
    }

    public var body: some View {
        switch axis {
        case .horizontal:
            HStack(spacing: itemSpacing) {
                ForEach(items, id: \.tab) { item in
                    itemView(item)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: maxItemWidth)
                }
            }
            /// Centres the items when they don't fill the width.
            .frame(maxWidth: .infinity)
            .font(.system(size: 10))
            .padding(.bottom, 2)
            .padding(.horizontal, 1)
            .frame(height: 50)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Tab bar"))
        case .vertical:
            VStack(spacing: 0) {
                ForEach(items, id: \.tab) { item in
                    itemView(item)
                        .frame(maxWidth: .infinity)
                        .frame(height: verticalItemHeight)
                        .padding(.horizontal, 4)
                }
            }
            .font(.system(size: 10))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Tab bar"))
        }
    }

    /// The widest a horizontal item can be, including its padding.
    var maxItemWidth: CGFloat {
        switch itemPositioning {
        case .fill: .infinity
        case let .centered(maxItemWidth, _): maxItemWidth
        }
    }

    /// The space between horizontal items.
    var itemSpacing: CGFloat {
        switch itemPositioning {
        case .fill: 0
        case let .centered(_, spacing): spacing
        }
    }

    func itemView(_ item: TabMenuItem<Tab>) -> some View {
        HStack {
            maskedView(selection == item.tab)
                .mask(
                    VStack(spacing: 2) {
                        Spacer(minLength: 0)

                        item.icon
                            .scaledToFit()
                            .frame(height: 22)

                        if isShowingName {
                            if let name = item.name {
                                Text(name)
                                    /// The vertical bar is narrow, so a long name truncates rather than wrapping.
                                    .lineLimit(axis == .vertical ? 1 : nil)
                            }
                        }

                        /// Centres the icon and name in a vertical item. A horizontal item keeps them at the bottom, as before.
                        if axis == .vertical {
                            Spacer(minLength: 0)
                        }
                    }
                )
                .onTapGesture {
                    if selection != item.tab {
                        selection = item.tab
                    }
                }
                .overlay(
                    Group {
                        if selection == item.tab {
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
                .accessibilityLabel(tabVoiceOverLabel(tabItem: item))
                .accessibilityHint(tabVoiceOverHint(tabItem: item))
                .accessibilityAddTraits(selection == item.tab ? .isSelected : [])
                .background(
                    ZStack {
                        if let onReselect, selection == item.tab {
                            Color.clear.accessibilityAction(named: onReselect.name, onReselect.action)
                        }
                        if let onDoubleTap, selection == item.tab {
                            Color.clear.accessibilityAction(named: onDoubleTap.name, onDoubleTap.action)
                        }
                    }
                )
                .accessibilityElement(children: .combine)
        }
    }
    
    func tabVoiceOverLabel(tabItem: TabMenuItem<Tab>) -> Text {
        let tabName = tabItem.name ?? "\(tabItem.tab.hashValue)"
        
        return Text(tabName)
    }
    
    func tabVoiceOverHint(tabItem: TabMenuItem<Tab>) -> Text {
        guard let tabIndex = items.firstIndex(where: { $0.tab == tabItem.tab }) else {
            return Text("")
        }
        
        return Text("Tab\n\(tabIndex + 1) of \(items.count)")
    }
    
    // Old Tab VoiceOver function
//    func tabVoiceOver(tabItem: TabMenuItem<Tab>) -> Text {
//        var tabString = ""
//        if let tabIndex = items.firstIndex(where: { $0.tab == tabItem.tab }) {
//            tabString = "\(tabIndex + 1) of \(items.count)"
//        }
//        let tabName = tabItem.name ?? "\(tabItem.tab.hashValue)"
//        
//        return Text("\(tabName)\nTab\n\(tabString)")
//    }
}
#endif
