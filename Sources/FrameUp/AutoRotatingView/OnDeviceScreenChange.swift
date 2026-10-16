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
    /// True to report only on a device with a hinge.
    var requiresHinge = false
    /// The action, with the new screen and whether it's the first report.
    let action: @MainActor (FUDeviceScreen, Bool) -> Void

    /// The last screen reported, or nil before the first report.
    @State private var reportedScreen: FUDeviceScreen? = nil

    func body(content: Content) -> some View {
        /// `onHingeChange` arrived in the iOS 27.1 SDK, whose SwiftUICore is version 8.0.85 (8.0.84 in the iOS 27.0 SDK). Both SDKs ship the same Swift compiler, so a compiler version check can't tell them apart.
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            content
                .onHingeChange { _, newContext in
                    guard newContext.hinge != nil || !requiresHinge else { return }
                    /// The scene moves between screens exactly when the hinge status changes (measured in the iPhone Duo simulator). No hinge, or a closed one, means the outer screen.
                    let screen: FUDeviceScreen = newContext.hinge.map { $0.status == .closed ? .outer : .inner } ?? .outer
                    /// The hinge reports every change of angle, so only pass on a change of screen.
                    guard screen != reportedScreen else { return }
                    let isFirstReport = reportedScreen == nil
                    reportedScreen = screen
                    action(screen, isFirstReport)
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
        modifier(OnDeviceScreenChange { screen, _ in action(screen) })
    }
}

public extension View {
    /// Adds an action to perform when a device with a hinge, such as a foldable iPhone, first reports the screen the view is on, and whenever the view moves to another screen.
    ///
    /// Unlike `onDeviceScreenChange(_:)`, the action only ever runs on a device with a hinge, so a report means the device folds: ``FUDeviceScreen/outer`` is then a foldable's outer screen, not the only screen of an iPhone that doesn't fold. Until the first report, and on any other device, the action doesn't run. It needs iOS 27.1 and the iOS 27.1 SDK or later.
    /// - Parameter action: The action to perform with the screen the view is on.
    /// - Returns: A view that performs the action when a device with a hinge reports its screen.
    @preconcurrency func onHingeScreenChange(_ action: @escaping @MainActor (FUDeviceScreen) -> Void) -> some View {
        modifier(OnDeviceScreenChange(requiresHinge: true) { screen, _ in action(screen) })
    }
}

internal extension View {
    /// Adds an action to perform when a device with a hinge first reports the screen the view is on, and whenever the view moves to another screen. The action passes the new screen, and true for the first report.
    func onHingeScreenChange(_ action: @escaping @MainActor (FUDeviceScreen, Bool) -> Void) -> some View {
        modifier(OnDeviceScreenChange(requiresHinge: true, action: action))
    }
}
#endif
