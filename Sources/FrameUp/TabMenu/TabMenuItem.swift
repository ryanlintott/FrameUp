//
//  TabMenuItem.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-15.
//

import SwiftUI

#if os(iOS)
/// A tab menu item that can be used in ``TabMenu``, built like a `Label` from a localized title and an icon.
///
/// The item style draws the label, and VoiceOver reads the label's title, even where the style hides it. An item is identified by its tab.
///
///     TabMenuItem("Favourites", systemImage: "star", tab: 1)
///     TabMenuItem("Info", tab: 0) {
///         Circle().stroke().overlay(Text("i"))
///     }
///     TabMenuItem(tab: 2, title: Text(category.name)) {
///         Image(systemName: "bookmark")
///     }
@available(iOS 16, *)
public struct TabMenuItem<Tab: Hashable>: Identifiable {
    /// Hashable tab id.
    public let tab: Tab

    /// The item's tab, which identifies it.
    public var id: Tab { tab }
    /// The title and icon, as a `Label`.
    public let label: Label<Text, TabMenuItemIcon>
    /// False only for an item made by a deprecated initialiser without a name, whose title is a stand-in. Remove with TabMenu+Deprecated.swift.
    var isNamed = true

    @MainActor
    private init(title: Text, icon: TabMenuItemIcon.Storage, tab: Tab) {
        self.tab = tab
        self.label = Label {
            title
        } icon: {
            TabMenuItemIcon(icon)
        }
    }

    /// Creates an item with a localized title and an SF Symbol for the icon.
    /// - Parameters:
    ///   - titleKey: The key for the item's localized title, looked up as `Label` does.
    ///   - systemImage: The name of the SF Symbol used as the icon.
    ///   - tab: Hashable tab id.
    @MainActor
    public init(_ titleKey: LocalizedStringKey, systemImage: String, tab: Tab) {
        self.init(title: Text(titleKey), icon: .image(Image(systemName: systemImage)), tab: tab)
    }

    /// Creates an item with a localized title and an image resource for the icon.
    /// - Parameters:
    ///   - titleKey: The key for the item's localized title, looked up as `Label` does.
    ///   - image: The image resource used as the icon.
    ///   - tab: Hashable tab id.
    @available(iOS 17, *)
    @MainActor
    public init(_ titleKey: LocalizedStringKey, image: ImageResource, tab: Tab) {
        self.init(title: Text(titleKey), icon: .image(Image(image)), tab: tab)
    }

    /// Creates an item with a localized title and any view for the icon.
    /// - Parameters:
    ///   - titleKey: The key for the item's localized title, looked up as `Label` does.
    ///   - tab: Hashable tab id.
    ///   - icon: The view used as the icon.
    @MainActor
    public init<Icon: View>(_ titleKey: LocalizedStringKey, tab: Tab, @ViewBuilder icon: () -> Icon) {
        self.init(title: Text(titleKey), icon: TabMenuItemIcon.Storage(icon()), tab: tab)
    }

    /// Creates an item with a title and any view for the icon, as `Label(title:icon:)` does.
    ///
    /// Use it for a title that isn't a localized string key, such as one made from data or with its own formatting.
    /// - Parameters:
    ///   - tab: Hashable tab id.
    ///   - title: The item's title. VoiceOver reads it as the item's name.
    ///   - icon: The view used as the icon.
    @MainActor
    public init<Icon: View>(tab: Tab, title: Text, @ViewBuilder icon: () -> Icon) {
        self.init(title: title, icon: TabMenuItemIcon.Storage(icon()), tab: tab)
    }
}
#endif
