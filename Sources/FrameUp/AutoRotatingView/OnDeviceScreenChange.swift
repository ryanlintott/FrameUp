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

/// Reports the device screen whenever the hinge changes it, and not again for the same screen.
///
/// SwiftUI's `onHingeChange` only reports changes, so a view that appears after the hinge has settled hears nothing until the next fold or unfold. `FUDeviceScreen(windowScene:)` gives the screen a view starts on.
fileprivate struct OnHingeScreenChange: ViewModifier {
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
    /// Adds an action to perform when the view's window scene moves to another screen of a device that folds, such as the iPhone Duo.
    ///
    /// The screen comes from the view's own window scene, so it's known as soon as the view appears, and it changes when the interface has moved, just before the system lays it out on the new screen. On a device that doesn't fold the screen is nil. Before the app has a window scene a foldable iPhone can't be told apart, so the screen can start as nil and change once it's known.
    ///
    /// ``SwiftUICore/View/onHingeScreenChange(_:)`` reports earlier, as the hinge moves, but only changes, and on the screen the interface is leaving.
    /// - Parameters:
    ///   - initial: True to perform the action with the screen the view is on when it appears.
    ///   - action: The action to perform with the screen the view's window scene is on, or nil on a device that doesn't fold.
    /// - Returns: A view that performs the action when its window scene moves to another screen.
    @preconcurrency func onDeviceScreenChange(initial: Bool = false, _ action: @escaping @MainActor (FUDeviceScreen?) -> Void) -> some View {
        modifier(OnSceneScreenChange(initial: initial, action: action))
    }

    /// Adds an action to perform when the hinge of a device that folds, such as a foldable iPhone, first reports the screen the view is on, and whenever it moves the view to another screen.
    ///
    /// The hinge reports as it moves, 55 to 500 milliseconds before the interface moves to the new screen, so this suits work that should start early. To know the screen the view is on, use ``SwiftUICore/View/onDeviceScreenChange(initial:_:)``: it reports when the window scene has moved, and gives the screen a view starts on.
    ///
    /// The hinge's first report comes soon after launch. A view that appears after that hears nothing until the next fold or unfold. The action only runs on a device with a hinge. It needs iOS 27.1 and the iOS 27.1 SDK.
    /// - Parameter action: The action to perform with the screen the hinge moves the view to.
    /// - Returns: A view that performs the action when the hinge reports a new screen.
    @preconcurrency func onHingeScreenChange(_ action: @escaping @MainActor (FUDeviceScreen) -> Void) -> some View {
        modifier(OnHingeScreenChange(action: action))
    }
}
#endif
