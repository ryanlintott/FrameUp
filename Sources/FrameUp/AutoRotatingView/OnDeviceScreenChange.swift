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

/// Reports the device screen whenever it changes on a device with a hinge, and not again for the same screen.
fileprivate struct OnDeviceScreenChange: ViewModifier {
    /// The action, with the new screen and whether it's the first report.
    let action: @MainActor (FUDeviceScreen, Bool) -> Void

    /// The last screen reported, or nil before the first report.
    @State private var reportedScreen: FUDeviceScreen? = nil

    func body(content: Content) -> some View {
        /// `onHingeChange` needs the iOS 27.1 SDK (SwiftUICore 8.0.85), which a compiler check can't detect.
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            content
                .onHingeChange { _, newContext in
                    guard let hinge = newContext.hinge else { return }
                    let screen: FUDeviceScreen = hinge.status == .closed ? .outer : .inner
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
    /// Adds an action to perform when a device with a hinge, such as a foldable iPhone, first reports the screen the view is on, and whenever the view moves to another screen.
    ///
    /// The action only runs on a device with a hinge. It needs iOS 27.1 and the iOS 27.1 SDK.
    /// - Parameter action: The action to perform with the screen the view is on.
    /// - Returns: A view that performs the action when a device with a hinge reports its screen.
    @preconcurrency func onHingeScreenChange(_ action: @escaping @MainActor (FUDeviceScreen) -> Void) -> some View {
        modifier(OnDeviceScreenChange { screen, _ in action(screen) })
    }
}

internal extension View {
    /// Adds an action to perform when a device with a hinge first reports the screen the view is on, and whenever the view moves to another screen. The action passes the new screen, and true for the first report.
    func onHingeScreenChange(_ action: @escaping @MainActor (FUDeviceScreen, Bool) -> Void) -> some View {
        modifier(OnDeviceScreenChange(action: action))
    }
}
#endif
