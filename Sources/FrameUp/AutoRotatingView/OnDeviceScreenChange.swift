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
    /// It tells the screen at once, where SwiftUI's `onHingeChange` only reports changes.
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

/// The screens a view has been on, which tells when to report another.
internal struct DeviceScreenReport: Hashable, Sendable {
    /// True once a screen has been seen.
    private(set) var hasSeen = false
    /// The screen last seen: nil on a device that doesn't fold, or before it's known to fold.
    private(set) var screen: FUDeviceScreen? = nil

    /// Takes the screen a view is on.
    /// - Parameters:
    ///   - newScreen: The screen the view's window scene is on, or nil on a device that doesn't fold.
    ///   - initial: True to report the first screen seen.
    /// - Returns: True when the screen should be reported: the first one if `initial` is true, and any that differs from the last one seen.
    mutating func see(_ newScreen: FUDeviceScreen?, initial: Bool) -> Bool {
        defer {
            hasSeen = true
            screen = newScreen
        }
        return hasSeen ? newScreen != screen : initial
    }
}

/// An empty view that passes on its window when it moves to one, and when the window scene's effective geometry changes.
fileprivate struct WindowSceneReader: UIViewRepresentable {
    let action: (UIWindow) -> Void

    func makeUIView(context: Context) -> WindowSceneAnchorView {
        let view = WindowSceneAnchorView()
        view.isUserInteractionEnabled = false
        updateUIView(view, context: context)
        return view
    }

    func updateUIView(_ view: WindowSceneAnchorView, context: Context) {
        view.windowAction = action
        view.geometryAction = { [weak view] in
            guard let window = view?.window else { return }
            action(window)
        }
    }
}

/// Reports the device screen a view's window scene is on, when the scene moves there.
fileprivate struct OnSceneScreenChange: ViewModifier {
    let initial: Bool
    let action: @MainActor (FUDeviceScreen?) -> Void

    @State private var report = DeviceScreenReport()
    /// The window this view is in, once it's in one.
    @State private var window = WindowReference()

    func body(content: Content) -> some View {
        content
            .background(
                WindowSceneReader { newWindow in
                    window = WindowReference(window: newWindow)
                    see()
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            )
            .onAppear {
                see()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                /// The device can fold or unfold in the background.
                see()
            }
    }

    /// Reports the screen of this view's window scene if it's one to report. Before the view is in a window, the app's window scene when it has only one.
    private func see() {
        let screen = FUDeviceScreen(windowScene: window.window?.windowScene ?? .onlyApplicationScene)
        guard report.see(screen, initial: initial) else { return }
        action(screen)
    }
}

public extension View {
    /// Adds an action to perform when the view's window scene moves to another screen of a device that folds, such as the iPhone Duo.
    ///
    /// The screen comes from the view's own window scene, so it's known as soon as the view appears, and it changes when the interface has moved, just before the system lays it out on the new screen. On a device that doesn't fold the screen is nil. Before the app has a window scene a foldable iPhone can't be told apart, so the screen can start as nil and change once it's known.
    ///
    /// SwiftUI's `onHingeChange` reports earlier, 55 to 500 milliseconds before the interface moves, but only changes, so a view that appears after the hinge has settled hears nothing until the next fold or unfold.
    /// - Parameters:
    ///   - initial: True to perform the action with the screen the view is on when it appears.
    ///   - action: The action to perform with the screen the view's window scene is on, or nil on a device that doesn't fold.
    /// - Returns: A view that performs the action when its window scene moves to another screen.
    func onDeviceScreenChange(initial: Bool = false, _ action: @escaping @MainActor (FUDeviceScreen?) -> Void) -> some View {
        modifier(OnSceneScreenChange(initial: initial, action: action))
    }
}
#endif
