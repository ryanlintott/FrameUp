//
//  TabMenu+Deprecated.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-10.
//

import SwiftUI

#if os(iOS)
/// An action with a name, used by the deprecated `TabMenu` initialiser for its reselect and double-tap actions.
@available(*, deprecated, message: "Use onTabMenuItemReselect(_:perform:) and onTabMenuItemDoubleTap(_:perform:) on the menu or a view above it.")
public struct NamedAction {
    public let name: Text
    public let action: () -> Void
}

@available(*, deprecated, message: "Use onTabMenuItemReselect(_:perform:) and onTabMenuItemDoubleTap(_:perform:) on the menu or a view above it.")
public extension NamedAction {
    init(_ name: LocalizedStringKey, action: @escaping () -> Void) {
        self.name = Text(name)
        self.action = action
    }
}

public extension TabMenu {
    /// Creates a tab menu with a masked view and actions, as in FrameUp 0.9.
    ///
    /// The masked view and actions take precedence over any set in the environment.
    /// - Parameters:
    ///   - selection: binding for the selected tab
    ///   - items: array of `TabMenuItem`
    ///   - isShowingName: A Boolean value that indicates whether the name should be shown. Default is true if any tab menu item has a name.
    ///   - maskedView: A view that will be shown, masked by the icon and text. A Boolean value with the selected state is passed in.
    ///   - onReselect: A named action to run when a selected tab is reselected.
    ///   - onDoubleTap: A named action to run when a selected tab is tapped twice.
    @available(*, deprecated, message: "Use TabMenu(selection:items:) with .tabMenuItemStyle(.masked { isSelected in ... }), .onTabMenuItemReselect(_:perform:) and .onTabMenuItemDoubleTap(_:perform:). To hide names, use an item style with .labelStyle(.iconOnly).")
    init<Content: View>(selection: Binding<Tab>, items: [TabMenuItem<Tab>], isShowingName: Bool? = nil, maskedView: @escaping (Bool) -> Content, onReselect: (() -> NamedAction)? = nil, onDoubleTap: (() -> NamedAction)? = nil) {
        self.init(selection: selection, items: items)
        let showsTitle = isShowingName ?? items.contains(where: \.isNamed)
        self.itemStyleOverride = MaskedTabMenuItemStyle(fill: maskedView, showsTitle: showsTitle)
        self.reselectOverride = onReselect.map { TabMenuItemAction($0()) }
        self.doubleTapOverride = onDoubleTap.map { TabMenuItemAction($0()) }
    }
}

extension TabMenuItemAction {
    @available(*, deprecated)
    init(_ namedAction: NamedAction) {
        self.init(name: namedAction.name, action: namedAction.action)
    }
}

public extension TabMenuItem {
    /// Creates an item with any view as the icon and an optional name, as in FrameUp 0.9.
    ///
    /// Without a name, the tab's description stands in as the title, which VoiceOver reads.
    @available(*, deprecated, message: "Use TabMenuItem(_:tab:icon:), such as TabMenuItem(\"Info\", tab: 0) { icon }. A title is required; hide titles with an item style using .labelStyle(.iconOnly).")
    @MainActor
    init(icon: AnyView, name: String? = nil, tab: Tab) {
        self.init(tab: tab, title: Text(verbatim: name ?? String(describing: tab))) { icon }
        self.isNamed = name != nil
    }

    /// Creates an item with an image as the icon and an optional name, as in FrameUp 0.9.
    ///
    /// Without a name, the tab's description stands in as the title, which VoiceOver reads.
    @available(*, deprecated, message: "Use TabMenuItem(_:systemImage:tab:), TabMenuItem(_:image:tab:) or TabMenuItem(_:tab:icon:). A title is required; hide titles with an item style using .labelStyle(.iconOnly).")
    @MainActor
    init(image: Image, name: String? = nil, tab: Tab) {
        self.init(tab: tab, title: Text(verbatim: name ?? String(describing: tab))) { image }
        self.isNamed = name != nil
    }

    @available(*, unavailable, message: "TabMenuItem holds a Label. Use label, or keep the icon alongside your items.")
    var icon: AnyView { fatalError("Unavailable") }

    @available(*, unavailable, message: "TabMenuItem holds a Label. Use label, or keep the name alongside your items.")
    var name: String? { fatalError("Unavailable") }

    /// Compares the tabs of two items, as `TabMenuItem`'s `Equatable` conformance did in FrameUp 0.9.
    @available(*, deprecated, message: "TabMenuItem is Identifiable, not Equatable. Compare the tabs instead: lhs.tab == rhs.tab.")
    static func == (lhs: TabMenuItem<Tab>, rhs: TabMenuItem<Tab>) -> Bool {
        lhs.tab == rhs.tab
    }
}
#endif
