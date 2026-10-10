//
//  TabMenuItemStyle.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-09.
//

import SwiftUI

#if os(iOS)
/// A type that draws each item in a ``TabMenu``.
///
/// Set it with `tabMenuItemStyle(_:)` on the menu or on any view above it, as with `ButtonStyle` and `LabelStyle`. It works the same whether `tabMenu(selection:items:)` places the menu or it's placed by hand.
///
/// The style only draws. `TabMenu` keeps the selection, the taps and the accessibility, and gives each item a cell: the full height and a share of the width along the bottom, or a share of the height and the full width in a vertical bar. The style's body is centred in the cell, and the whole cell takes taps.
///
///     struct CapsuleItemStyle: TabMenuItemStyle {
///         func makeBody(configuration: Configuration) -> some View {
///             configuration.label
///                 .labelStyle(configuration.axis == .vertical ? .iconOnly : .titleAndIcon)
///                 .padding(6)
///                 .background {
///                     if configuration.isSelected {
///                         Capsule().fill(.tint.opacity(0.3))
///                     }
///                 }
///         }
///     }
public protocol TabMenuItemStyle {
    /// A view that represents the body of an item.
    associatedtype Body: View

    /// Creates a view that represents the body of an item.
    /// - Parameter configuration: The properties of the item.
    @MainActor @ViewBuilder func makeBody(configuration: Configuration) -> Body

    /// The properties of an item.
    typealias Configuration = TabMenuItemStyleConfiguration
}

/// The properties of an item in a ``TabMenu``, passed to a ``TabMenuItemStyle``.
public struct TabMenuItemStyleConfiguration {
    /// The item's title and icon, as given in ``TabMenuItem``.
    public let label: Label<Text, TabMenuItemIcon>
    /// A Boolean value that indicates whether the item is selected.
    public let isSelected: Bool
    /// The screen edge the menu is placed against: `.bottom`, `.leading` or `.trailing`. Nil for a ``TabMenu`` placed by hand, which can't know where it is.
    ///
    /// Like ``SwiftUICore/EnvironmentValues/tabMenuVerticalEdge``, it's layout-relative: in a right-to-left layout a bar on the physical right is `.leading`.
    public let edge: Edge?

    /// `.vertical` when `edge` is leading or trailing, otherwise `.horizontal`.
    public var axis: Axis {
        switch edge {
        case .leading, .trailing: .vertical
        case .top, .bottom, nil: .horizontal
        }
    }
}

public extension View {
    /// Sets the style that draws the items of tab menus in this view.
    ///
    /// It can go outside `tabMenu(selection:items:)`, since the menu is inside it.
    ///
    ///     ContentView()
    ///         .tabMenu(selection: $selection, items: items)
    ///         .tabMenuItemStyle(.masked { isSelected in
    ///             isSelected ? Color.orange : Color.gray
    ///         })
    ///
    /// - Parameter style: The style that draws each item. Default is ``TabMenuItemStyle/automatic``.
    /// - Returns: A view whose tab menus draw their items with this style.
    func tabMenuItemStyle<S: TabMenuItemStyle>(_ style: S) -> some View {
        environment(\.tabMenuItemStyle, style)
    }
}
#endif
