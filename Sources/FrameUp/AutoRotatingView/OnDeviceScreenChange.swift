//
//  OnDeviceScreenChange.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-24.
//

#if os(iOS)
import SwiftUI

/// One of the device's built-in screens.
public enum FUDeviceScreen: Hashable, Sendable, CaseIterable {
    /// The screen on the outside of the device, which is the only screen on a device that doesn't fold.
    case outer
    /// The inner screen of a foldable iPhone, shown while the hinge is open.
    case inner
}

/// Reports the device screen whenever it changes, and not again for the same screen.
fileprivate struct OnDeviceScreenChange: ViewModifier {
    let action: @MainActor (FUDeviceScreen) -> Void

    /// The last screen reported, or nil before the first report.
    @State private var reportedScreen: FUDeviceScreen? = nil

    func body(content: Content) -> some View {
        /// `onHingeChange` arrived in the iOS 27.1 SDK, whose SwiftUICore is version 8.0.85 (8.0.84 in the iOS 27.0 SDK). Both SDKs ship the same Swift compiler, so a compiler version check can't tell them apart.
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            content
                .onHingeChange { _, newContext in
                    /// The scene moves between screens exactly when the hinge status changes (measured in the iPhone Duo simulator). No hinge, or a closed one, means the outer screen.
                    let screen: FUDeviceScreen = newContext.hinge.map { $0.status == .closed ? .outer : .inner } ?? .outer
                    /// The hinge reports every change of angle, so only pass on a change of screen.
                    guard screen != reportedScreen else { return }
                    reportedScreen = screen
                    action(screen)
                }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

public extension View {
    /// Adds an action to perform when the view moves between the device's built-in screens, such as when a foldable iPhone is folded or unfolded.
    ///
    /// The action also runs with the screen the view starts on, once the system reports it. The view is on the inner screen whenever a foldable iPhone's hinge is open.
    ///
    /// The screen is read from the device's hinge, which requires iOS 27.1 and building with the iOS 27.1 SDK or later. On earlier versions, where no device folds, the action never runs. On a device without a hinge the screen is always ``FUDeviceScreen/outer``, and the action may never run.
    /// - Parameter action: The action to perform when the screen changes. The action closure passes the new screen as its parameter.
    /// - Returns: A view that performs the action when the device screen changes.
    @preconcurrency func onDeviceScreenChange(_ action: @escaping @MainActor (FUDeviceScreen) -> Void) -> some View {
        modifier(OnDeviceScreenChange(action: action))
    }
}
#endif
