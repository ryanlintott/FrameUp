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

internal extension FUDeviceScreen {
    /// The device screen a screen is. The outer screen stays the main screen while the inner screen shows.
    @MainActor
    init(_ screen: UIScreen) {
        self = screen.nativeBounds == UIScreen.main.nativeBounds ? .outer : .inner
    }
}

internal extension FUDeviceScreen {
    /// The screen a window scene is on, on a device that folds. Nil on a device that doesn't, or when the scene isn't the app's own interactive one.
    ///
    /// It tells the screen at once, where the hinge only reports changes.
    @MainActor
    init?(windowScene: UIWindowScene?) {
        FUFoldability.update(from: windowScene)
        guard let windowScene, windowScene.isApplicationScene,
              let screen = Self.screen(isFoldable: FUFoldability.current == .foldable, isSceneOnMainScreen: FUDeviceScreen(windowScene.screen) == .outer)
        else { return nil }
        self = screen
    }

    /// The screen the app's scene is on, on a device that folds, or nil on one that doesn't. The outer screen stays the main screen while the inner screen shows.
    static func screen(isFoldable: Bool, isSceneOnMainScreen: Bool) -> Self? {
        guard isFoldable else { return nil }
        return isSceneOnMainScreen ? .outer : .inner
    }
}

#if canImport(SwiftUICore, _version: 8.0.85)
@available(iOS 27.1, *)
internal extension FUDeviceScreen {
    /// The screen a hinge status shows: the outer screen when it's closed, and the inner screen when it's open at all.
    init(hingeStatus: DeviceHinge.Status) {
        self = hingeStatus == .closed ? .outer : .inner
    }
}
#endif

/// Reports the device screen whenever the hinge changes it, and not again for the same screen.
///
/// SwiftUI's `onHingeChange` only reports changes, so a view that appears after the hinge has settled hears nothing until the next fold or unfold. `FUDeviceScreen(windowScene:)` gives the screen a view starts on.
fileprivate struct OnDeviceScreenChange: ViewModifier {
    let action: @MainActor (FUDeviceScreen) -> Void

    /// The last screen reported, or nil before the first report.
    @State private var reportedScreen: FUDeviceScreen? = nil

    func body(content: Content) -> some View {
        /// `onHingeChange` needs the iOS 27.1 SDK (SwiftUICore 8.0.85), which a compiler check can't detect.
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            content
                .onHingeChange { _, newContext in
                    guard let hinge = newContext.hinge else { return }
                    FUFoldability.hingeDidReport()
                    report(FUDeviceScreen(hingeStatus: hinge.status))
                }
        } else {
            content
        }
        #else
        content
        #endif
    }

    /// Passes on a screen that's new. The hinge reports every change of angle, so the same screen comes again and again.
    private func report(_ screen: FUDeviceScreen) {
        guard screen != reportedScreen else { return }
        reportedScreen = screen
        action(screen)
    }
}

public extension View {
    /// Adds an action to perform when a device with a hinge, such as a foldable iPhone, first reports the screen the view is on, and whenever the view moves to another screen.
    ///
    /// It reports when the hinge changes the screen, including its first report soon after launch. A view that appears after that hears nothing until the next fold or unfold; use `UIDevice.current.isFoldable` to tell whether the device folds. The action only runs on a device with a hinge. It needs iOS 27.1 and the iOS 27.1 SDK.
    /// - Parameter action: The action to perform with the screen the view is on.
    /// - Returns: A view that performs the action when a device with a hinge reports its screen.
    @preconcurrency func onHingeScreenChange(_ action: @escaping @MainActor (FUDeviceScreen) -> Void) -> some View {
        modifier(OnDeviceScreenChange(action: action))
    }
}
#endif
