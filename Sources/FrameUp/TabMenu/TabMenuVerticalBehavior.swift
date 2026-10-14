//
//  TabMenuVerticalBehavior.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-08.
//

import SwiftUI

#if os(iOS)
/// Where a menu placed with `tabMenu(selection:items:)` can stack its items in a vertical bar instead of a horizontal bar along the bottom.
///
/// Modelled on the system's `toolbarVerticalBehavior(_:)`. Set it with `tabMenuVerticalBehavior(_:)` above the tab menu, and read where the vertical bar is from ``SwiftUICore/EnvironmentValues/tabMenuVerticalEdge``.
///
/// `tabMenuVerticalBehavior(_:)` sets `toolbarVerticalBehavior(_:)` to match, but a `toolbarVerticalBehavior(_:)` the app applies further out takes precedence. So if the app turns the system's vertical toolbar off further out, the menu can't use it, even with `.automatic`.
public enum TabMenuVerticalBehavior: Hashable, Sendable {
    /// The menu is vertical only in the system's vertical toolbar, as on the iPhone Duo, and never makes a custom vertical bar. This is the default.
    case system
    /// The menu is vertical on every iPhone: in the system's vertical toolbar, which it turns on with `toolbarVerticalBehavior(.automatic)`, and elsewhere in landscape, in a custom vertical bar on the edge away from the Dynamic Island. The content moves over to make room for the custom bar. This needs iOS 16.
    ///
    /// Where the app has turned the system's vertical toolbar off with `toolbarVerticalBehavior(.disabled)` further out, as on the iPhone Duo, the menu only uses the custom bar, which needs a compact height. On the Duo that's the outer screen in landscape; elsewhere the menu runs along the bottom.
    case automatic
    /// The menu always runs along the bottom, and turns off the system's vertical toolbar with `toolbarVerticalBehavior(.disabled)`.
    case disabled
}

public extension View {
    /// Sets where menus placed with `tabMenu(selection:items:)` inside this view can stack their items in a vertical bar, and sets ``SwiftUICore/EnvironmentValues/tabMenuVerticalEdge`` to match for everything inside it.
    ///
    /// Apply it above the tab menu, such as at the root of a scene.
    ///
    ///     ContentView()
    ///         .tabMenu(selection: $selection, items: items)
    ///         .tabMenuVerticalBehavior(.automatic)
    ///
    /// - Parameter behavior: `.system` to use only the system's vertical bar, `.automatic` to also use a custom vertical bar on an iPhone in landscape, or `.disabled` to keep the menu along the bottom.
    /// - Returns: A view that places its tab menus with this behavior.
    @ViewBuilder
    func tabMenuVerticalBehavior(_ behavior: TabMenuVerticalBehavior) -> some View {
        if #available(iOS 16, *) {
            modifier(TabMenuEnvironmentModifier(behavior: behavior))
        } else {
            /// Vertical bars need iOS 16, so before that there's nothing to set. The version never changes while the app runs, so this branch can't reset the content's state.
            self
        }
    }
}

/// Sets the behavior and tracks the interface orientation for tab menus inside it, and sets the system's vertical toolbar to match.
@available(iOS 16, *)
private struct TabMenuEnvironmentModifier: ViewModifier {
    /// The interface orientation, read from the window scene from the first update, so the menu never waits for it.
    @State private var orientation: FUInterfaceOrientation? = .windowScene

    let behavior: TabMenuVerticalBehavior

    func body(content: Content) -> some View {
        content
            .environment(\.tabMenuVerticalBehavior, behavior)
            .environment(\.tabMenuInterfaceOrientation, orientation)
            /// A rotation straight from one landscape orientation to the other changes neither the size nor the size classes, so the device's turn is the signal. The window scene's orientation hasn't changed yet when it arrives, so this follows the device, as AutoRotatingView does, wherever the app supports the orientation it has turned to.
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                if let newOrientation = UIDevice.current.orientation.interfaceOrientation,
                   InfoDictionary.supportedInterfaceOrientations.contains(newOrientation) {
                    orientation = newOrientation
                }
            }
            .modifier(UpdateToolbarVerticalBehaviorModifier(tabMenuVerticalBehavior: behavior))
    }
}

/// Sets the system's vertical toolbar to match ``TabMenuVerticalBehavior``: on for `.system` and `.automatic`, so the menu can use it on the iPhone Duo, and off for `.disabled`, so there's no empty vertical toolbar beside the bottom menu.
///
/// It always applies a behavior rather than leaving the app's alone for `.system`. Choosing one only for some cases would branch the content, resetting its state when the behavior changes, and turning the toolbar off for `.system` whenever `toolbarVerticalEdge` is nil would keep it off, since the toolbar is what sets that edge.
@available(iOS 16, *)
private struct UpdateToolbarVerticalBehaviorModifier: ViewModifier {
    let tabMenuVerticalBehavior: TabMenuVerticalBehavior

    func body(content: Content) -> some View {
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            content
                .toolbarVerticalBehavior(tabMenuVerticalBehavior == .disabled ? .disabled : .automatic)
        } else {
            content
        }
        #else
        content
        #endif
    }
}
#endif
