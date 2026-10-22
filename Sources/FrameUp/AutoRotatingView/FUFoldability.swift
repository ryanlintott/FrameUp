//
//  FUFoldability.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-21.
//

#if os(iOS)
import SwiftUI

/// Whether the device folds, as far as FrameUp knows yet.
///
/// Before iOS 27.1, and on an iPad, nothing folds. Otherwise the app's window scene tells at once: on a foldable iPhone it's either on the inner screen, which isn't the main screen, or on the outer screen, which uses the vertical bar in every orientation. Only before the app has a window scene is it unknown.
internal enum FUFoldability: Hashable, Sendable {
    /// Not known yet, before the app has a window scene.
    case unknown
    /// The device folds.
    case foldable
    /// The device doesn't fold.
    case notFoldable

    /// What a window scene shows about the device.
    /// - Parameters:
    ///   - supportsFolding: True on an iPhone with iOS 27.1, built with its SDK.
    ///   - isSceneOnMainScreen: True when the app's window scene is on the main screen, or nil when there's no app window scene to go by.
    ///   - hasVerticalBar: True when the scene's traits give the vertical bar an edge, whether or not the app shows it.
    static func detect(supportsFolding: Bool, isSceneOnMainScreen: Bool?, hasVerticalBar: Bool) -> Self {
        guard supportsFolding else { return .notFoldable }
        guard let isSceneOnMainScreen else { return .unknown }
        /// Only a foldable has a second built-in screen. An external display never holds the app's own interactive scene on an iPhone.
        if !isSceneOnMainScreen { return .foldable }
        /// The outer screen of a foldable uses the vertical bar in every orientation. No other iPhone has one.
        if hasVerticalBar { return .foldable }
        return .notFoldable
    }

    @MainActor
    private static var known: Self = .unknown

    /// What's known so far, shared by every view. Once known it's never changed by a window scene: a device doesn't start or stop folding.
    @MainActor
    static var current: Self {
        if known == .unknown {
            update(from: .onlyApplicationScene)
        }
        return known
    }

    /// Learns what it can from a window scene, if it isn't known yet.
    @MainActor
    static func update(from windowScene: UIWindowScene?) {
        guard known == .unknown else { return }
        let appScene = windowScene.flatMap { $0.isApplicationScene ? $0 : nil }
        known = detect(
            supportsFolding: sdkSupportsFolding,
            isSceneOnMainScreen: appScene.map { FUDeviceScreen($0.screen) == .outer },
            hasVerticalBar: appScene.map(hasVerticalBar) ?? false
        )
    }

    /// True on an iPhone with iOS 27.1, built with its SDK.
    @MainActor
    private static var sdkSupportsFolding: Bool {
        /// The hinge API needs the iOS 27.1 SDK (SwiftUICore 8.0.85), which a compiler check can't detect.
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            return UIDevice.current.userInterfaceIdiom == .phone
        }
        #endif
        return false
    }

    /// True when the scene's traits give the vertical bar an edge. The trait gives the system's edge whether or not the app shows the bar.
    @MainActor
    private static func hasVerticalBar(_ windowScene: UIWindowScene) -> Bool {
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            return windowScene.traitCollection.verticalBarEdge != .unspecified
        }
        #endif
        return false
    }
}

public extension UIDevice {
    /// True on a device that folds, such as the iPhone Duo.
    ///
    /// It's known as soon as the app has a window scene, before any view appears: from the scene being on the inner screen, or from the outer screen's vertical bar, whether or not the app shows the bar. Before that, and before iOS 27.1 or on an iPad, it's false.
    @MainActor var isFoldable: Bool {
        FUFoldability.current == .foldable
    }
}
#endif
