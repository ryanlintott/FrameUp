//
//  MaskedTabMenuItemStyle.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-09.
//

import SwiftUI

#if os(iOS)
/// A tab menu item style that shows a fill masked by the item's icon and title, as the iPhone tab bar in iOS 15–18 looks.
///
/// The icon is 22 points tall above a 10 point title. Along the bottom they sit at the bottom of the item; in a vertical bar they're centred, and the title truncates rather than wrapping. Use ``TabMenuItemStyle/masked(_:)`` to create one.
@available(iOS 16, *)
public struct MaskedTabMenuItemStyle<Fill: View>: TabMenuItemStyle {
    let fill: (Bool) -> Fill
    /// False only for the deprecated `TabMenu` initialiser's `isShowingName: false`. VoiceOver still reads the title. Remove with TabMenu+Deprecated.swift.
    var showsTitle = true

    public func makeBody(configuration: Configuration) -> some View {
        fill(configuration.isSelected)
            .mask(
                configuration.label
                    .labelStyle(MaskedTabMenuItemLabelStyle(axis: configuration.axis, showsTitle: showsTitle))
            )
            /// VoiceOver can't read a mask, so it reads the label instead: its title, once.
            .accessibilityRepresentation {
                configuration.label
            }
    }
}

@available(iOS 16, *)
public extension TabMenuItemStyle {
    /// A style that shows a fill masked by each item's icon and title, as the iPhone tab bar in iOS 15–18 looks.
    ///
    ///     ContentView()
    ///         .tabMenu(selection: $selection, items: items)
    ///         .tabMenuItemStyle(.masked { isSelected in
    ///             isSelected ? Color.orange : Color.gray
    ///         })
    ///
    /// - Parameter fill: The view shown through the icon and title. A simple color or a more complex view can be provided. A Boolean value with the selected state is passed in so the view can change accordingly. It's called each time the menu updates, so it always sees the current state.
    /// - Returns: A masked item style.
    static func masked<Fill: View>(_ fill: @escaping (Bool) -> Fill) -> MaskedTabMenuItemStyle<Fill> where Self == MaskedTabMenuItemStyle<Fill> {
        MaskedTabMenuItemStyle(fill: fill)
    }
}

/// The default tab menu item style: ``MaskedTabMenuItemStyle`` with the accent color when selected and the secondary label color otherwise.
@available(iOS 16, *)
public struct AutomaticTabMenuItemStyle: TabMenuItemStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        MaskedTabMenuItemStyle { isSelected in
            isSelected ? Color.accentColor : Color(.secondaryLabel)
        }
        .makeBody(configuration: configuration)
    }
}

@available(iOS 16, *)
public extension TabMenuItemStyle where Self == AutomaticTabMenuItemStyle {
    /// The default style: a masked icon and title in the accent color when selected and the secondary label color otherwise.
    static var automatic: AutomaticTabMenuItemStyle { AutomaticTabMenuItemStyle() }
}

/// Lays out the icon and title for ``MaskedTabMenuItemStyle``, filling the item so they can be placed in it.
@available(iOS 16, *)
struct MaskedTabMenuItemLabelStyle: LabelStyle {
    let axis: Axis
    /// Passed on from ``MaskedTabMenuItemStyle``. Remove with TabMenu+Deprecated.swift.
    var showsTitle = true

    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 2) {
            Spacer(minLength: 0)

            configuration.icon
                /// An SF Symbol or image resource isn't resizable as given, so it would otherwise draw at its natural size.
                .environment(\.tabMenuItemIconIsResizable, true)
                .scaledToFit()
                .frame(height: 22)

            if showsTitle {
                configuration.title
                    /// The vertical bar is narrow, so a long title truncates rather than wrapping.
                    .lineLimit(axis == .vertical ? 1 : nil)
            }

            /// Centres the icon and title in a vertical item. A horizontal item keeps them at the bottom.
            if axis == .vertical {
                Spacer(minLength: 0)
            }
        }
        /// Also reaches text in a custom icon, as before this style existed.
        .font(.system(size: 10))
    }
}
#endif
