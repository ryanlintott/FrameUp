//
//  TabMenuItemAction.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-09.
//

import SwiftUI

#if os(iOS)
/// An action a ``TabMenu`` runs on its selected item, with the name VoiceOver offers it by.
@available(iOS 16, *)
struct TabMenuItemAction {
    let name: Text
    let action: () -> Void
}

@available(iOS 16, *)
public extension View {
    /// Runs an action when the selected item of a tab menu in this view is tapped again.
    ///
    /// It can go outside `tabMenu(selection:items:)`, since the menu is inside it, and doesn't reach a `TabMenu` in that view's content. The action is offered to VoiceOver by name on the selected item.
    ///
    ///     ContentView()
    ///         .tabMenu(selection: $selection, items: items)
    ///         .onTabMenuItemReselect("Scroll to top") {
    ///             scrollToTop()
    ///         }
    ///
    /// - Parameters:
    ///   - name: The key for the localized name of the VoiceOver action.
    ///   - action: The action to run.
    /// - Returns: A view whose tab menus run the action when the selected item is tapped again.
    func onTabMenuItemReselect(_ name: LocalizedStringKey, perform action: @escaping () -> Void) -> some View {
        onTabMenuItemReselect(Text(name), perform: action)
    }

    /// Runs an action when the selected item of a tab menu in this view is tapped again.
    ///
    /// It can go outside `tabMenu(selection:items:)`, since the menu is inside it, and doesn't reach a `TabMenu` in that view's content. The action is offered to VoiceOver by name on the selected item.
    /// - Parameters:
    ///   - name: The name of the VoiceOver action.
    ///   - action: The action to run.
    /// - Returns: A view whose tab menus run the action when the selected item is tapped again.
    func onTabMenuItemReselect(_ name: Text, perform action: @escaping () -> Void) -> some View {
        environment(\.tabMenuItemReselectAction, TabMenuItemAction(name: name, action: action))
    }

    /// Runs an action when the selected item of a tab menu in this view is tapped twice.
    ///
    /// It can go outside `tabMenu(selection:items:)`, since the menu is inside it, and doesn't reach a `TabMenu` in that view's content. With this set, a single tap on the selected item waits to rule out a double tap. The action is offered to VoiceOver by name on the selected item.
    ///
    ///     ContentView()
    ///         .tabMenu(selection: $selection, items: items)
    ///         .onTabMenuItemDoubleTap("Close cover") {
    ///             closeCover()
    ///         }
    ///
    /// - Parameters:
    ///   - name: The key for the localized name of the VoiceOver action.
    ///   - action: The action to run.
    /// - Returns: A view whose tab menus run the action when the selected item is tapped twice.
    func onTabMenuItemDoubleTap(_ name: LocalizedStringKey, perform action: @escaping () -> Void) -> some View {
        onTabMenuItemDoubleTap(Text(name), perform: action)
    }

    /// Runs an action when the selected item of a tab menu in this view is tapped twice.
    ///
    /// It can go outside `tabMenu(selection:items:)`, since the menu is inside it, and doesn't reach a `TabMenu` in that view's content. With this set, a single tap on the selected item waits to rule out a double tap. The action is offered to VoiceOver by name on the selected item.
    /// - Parameters:
    ///   - name: The name of the VoiceOver action.
    ///   - action: The action to run.
    /// - Returns: A view whose tab menus run the action when the selected item is tapped twice.
    func onTabMenuItemDoubleTap(_ name: Text, perform action: @escaping () -> Void) -> some View {
        environment(\.tabMenuItemDoubleTapAction, TabMenuItemAction(name: name, action: action))
    }
}

@available(iOS 16, *)
extension View {
    /// Clears the reselect and double-tap actions, so actions meant for a menu that `tabMenu(selection:items:)` places don't reach a `TabMenu` in its content.
    func tabMenuItemActionsDisabled() -> some View {
        environment(\.tabMenuItemReselectAction, nil)
            .environment(\.tabMenuItemDoubleTapAction, nil)
    }
}
#endif
