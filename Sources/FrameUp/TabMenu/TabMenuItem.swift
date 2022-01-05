//
//  TabMenuItem.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-15.
//

import SwiftUI

/// A tab menu item that can be used in TabMenuView.
public struct TabMenuItem<Tab: Hashable>: Equatable {
    /// Icon silhouette for the tab menu item.
    public let icon: AnyView
    /// Label used on the tab menu (nil for blank).
    public let name: String?
    /// Hashable tab id.
    public let tab: Tab
    
    /// Creates a TabMenuItem with any view as the icon, an optional label and a hashable tab id.
    /// - Parameters:
    ///   - icon: View used as the icon silhouette for the tab menu item.
    ///   - name: Label used on the tab menu (nil for blank).
    ///   - tab: Hashable tab id
    public init(icon: AnyView, name: String? = nil, tab: Tab) {
        self.icon = icon
        self.name = name
        self.tab = tab
    }
    
    /// Creates a TabMenuItem with an image for the icon, an optional label and a hashable tab id.
    /// - Parameters:
    ///   - image: Image used as the icon silhouette for the tab menu item.
    ///   - name: Label used on the tab menu (nil for blank).
    ///   - tab: Hashable tab id.
    public init(image: Image, name: String? = nil, tab: Tab) {
        self.icon = AnyView(image.resizable())
        self.name = name
        self.tab = tab
    }
    
    public static func == (lhs: TabMenuItem<Tab>, rhs: TabMenuItem<Tab>) -> Bool {
        lhs.tab == rhs.tab
    }
}
