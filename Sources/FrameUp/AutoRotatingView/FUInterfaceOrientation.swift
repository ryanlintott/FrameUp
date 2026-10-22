//
//  FUInterfaceOrientation.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-05-23.
//

#if os(iOS)
import SwiftUI

/// An orientation of the device, named for the way it's held. Landscape right is the device turned clockwise from portrait, the opposite of UIKit's interface orientation names.
public enum FUInterfaceOrientation: CaseIterable, Sendable {
    case portrait
    case landscapeRight
    case landscapeLeft
    case portraitUpsideDown
}

internal extension FUInterfaceOrientation {
    init?(key: String) {
        switch key {
        case "UIInterfaceOrientationPortrait":
            self = .portrait
        case "UIInterfaceOrientationLandscapeLeft":
            /// UIInterfaceOrientationLandscapeLeft means the interface has turned to the LEFT even though the device has turned to the RIGHT.
            self = .landscapeRight
        case "UIInterfaceOrientationLandscapeRight":
            /// UIInterfaceOrientationLandscapeRight means the interface has turned to the RIGHT even though the device has turned to the LEFT.
            self = .landscapeLeft
        case "UIInterfaceOrientationPortraitUpsideDown":
            self = .portraitUpsideDown
        default:
            return nil
        }
    }
    
    private var rotationFromPortrait: FUInterfaceRotation {
        switch self {
        case .portrait: .zero
        case .landscapeRight: .degrees270
        case .landscapeLeft: .degrees90
        case .portraitUpsideDown: .degrees180
        }
    }
    
    init(rotationFromPortrait: FUInterfaceRotation) {
        self = switch rotationFromPortrait {
        case .zero: .portrait
        case .degrees270: .landscapeRight
        case .degrees90: .landscapeLeft
        case .degrees180: .portraitUpsideDown
        }
    }
    
    /// How far this orientation is rotated clockwise relative to another. A quarter turn anticlockwise is ``FUInterfaceRotation/degrees270``.
    func rotation(from other: Self) -> FUInterfaceRotation {
        rotationFromPortrait - other.rotationFromPortrait
    }
    
    /// The orientation this one becomes when the interface turns by a rotation, as reported by a transition coordinator's `targetTransform`.
    func rotated(by rotation: FUInterfaceRotation) -> Self {
        .init(rotationFromPortrait: rotationFromPortrait + rotation)
    }
    
    /// The interface orientation once the system turns the interface by a rotation, as reported by a transition coordinator.
    /// - Parameters:
    ///   - rotation: The system's turn of the interface.
    ///   - orientation: The interface orientation before the turn, if known.
    ///   - sceneOrientation: The window scene's orientation, which has already turned by the time the coordinator reports the turn.
    static func afterSystemTurn(by rotation: FUInterfaceRotation, from orientation: Self?, sceneOrientation: Self?) -> Self? {
        orientation?.rotated(by: rotation) ?? sceneOrientation
    }

    /// The orientation in a list that is the smallest turn from this one. A quarter turn is nearer than a half turn, and the first in the list wins a tie.
    func nearest(in orientations: [Self]) -> Self? {
        orientations.min { rotation(from: $0).shortestQuarterTurns < rotation(from: $1).shortestQuarterTurns }
    }
}

internal extension FUInterfaceOrientation {
    /// The interface orientation of a window scene.
    @MainActor
    init?(windowScene scene: UIWindowScene) {
        let interfaceOrientation: UIInterfaceOrientation
        if #available(iOS 16, *) {
            interfaceOrientation = scene.effectiveGeometry.interfaceOrientation
        } else {
            interfaceOrientation = scene.interfaceOrientation
        }
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        /// UIKit names the interface's turn, the opposite of the device's.
        case .landscapeRight: self = .landscapeLeft
        case .landscapeLeft: self = .landscapeRight
        default: return nil
        }
    }

    /// The interface orientation of the app's foreground window scene.
    @MainActor
    static var windowScene: Self? {
        /// At launch the scene can still be inactive.
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.session.role == .windowApplication }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        return scene.flatMap(Self.init(windowScene:))
    }
}

internal extension UIWindowScene {
    /// True for the app's own interactive window scene, not one on an external display. On an iPhone it's always on a built-in screen.
    @MainActor
    var isApplicationScene: Bool {
        session.role == .windowApplication
    }

    /// The app's window scene when it has only one, or nil.
    @MainActor
    static var onlyApplicationScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter(\.isApplicationScene)
        return scenes.count == 1 ? scenes.first : nil
    }
}

/// A window, held weakly, that compares by identity.
internal struct WindowReference: Equatable {
    weak var window: UIWindow? = nil

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.window === rhs.window
    }
}

internal extension FUInterfaceOrientation {
    /// The interface orientations the system can turn a window to: the app's or scene's supported orientations, and those of the view controller at the top of the window.
    ///
    /// No API reports that an iPhone without a Home button doesn't turn to upside down.
    /// - Parameter window: The window, or nil for the app's supported orientations alone.
    @MainActor
    static func systemOrientations(in window: UIWindow?) -> [Self] {
        let application = UIApplication.shared
        var mask: UIInterfaceOrientationMask
        if #available(iOS 27, *), let scene = window?.windowScene, let sceneMask = (scene.delegate as? UIWindowSceneDelegate)?.supportedInterfaceOrientations?(for: scene) {
            mask = sceneMask
        } else if let appMask = application.delegate?.application?(application, supportedInterfaceOrientationsFor: window) {
            mask = appMask
        } else {
            /// The Info.plist value, or the platform's default.
            mask = application.supportedInterfaceOrientations(for: window)
        }
        if let window {
            if #available(iOS 26, *), let scene = window.windowScene, scene.effectiveGeometry.isInterfaceOrientationLocked {
                return Self(windowScene: scene).map { [$0] } ?? []
            }
            let isViewControllerFollowed = !Self.isMultitasking(
                idiom: UIDevice.current.userInterfaceIdiom,
                requiresFullScreen: Bundle.main.object(forInfoDictionaryKey: "UIRequiresFullScreen") as? Bool == true,
                infoPlistOrientations: application.supportedInterfaceOrientations(for: nil)
            )
            if isViewControllerFollowed, let viewController = window.topFullScreenViewController {
                mask.formIntersection(viewController.supportedInterfaceOrientations)
            }
        }
        return allCases.filter { mask.contains($0.mask) }
    }

    /// True when an app supports multitasking, so the system doesn't follow its view controllers' supported orientations. An iPad app opts out by requiring the full screen, or by not supporting every orientation in its Info.plist.
    /// - Parameters:
    ///   - idiom: The device's interface idiom.
    ///   - requiresFullScreen: The app's `UIRequiresFullScreen` value.
    ///   - infoPlistOrientations: The orientations in the app's Info.plist for the device.
    static func isMultitasking(idiom: UIUserInterfaceIdiom, requiresFullScreen: Bool, infoPlistOrientations: UIInterfaceOrientationMask) -> Bool {
        idiom == .pad && !requiresFullScreen && infoPlistOrientations.contains(.all)
    }

    /// The interface orientation mask of this orientation.
    var mask: UIInterfaceOrientationMask {
        switch self {
        case .portrait: .portrait
        case .portraitUpsideDown: .portraitUpsideDown
        /// UIKit names the interface's turn, the opposite of the device's.
        case .landscapeLeft: .landscapeRight
        case .landscapeRight: .landscapeLeft
        }
    }
}

internal extension UIWindow {
    /// The view controller whose supported orientations the system follows: the root, or the last one presented over the full screen.
    var topFullScreenViewController: UIViewController? {
        var viewController = rootViewController
        while let presented = viewController?.presentedViewController, presented.presentationController?.shouldPresentInFullscreen == true, !presented.isBeingDismissed {
            viewController = presented
        }
        return viewController
    }
}

internal extension Dictionary where Key == FUInterfaceOrientation, Value == FUInterfaceOrientation {
    /// A map from each orientation to itself.
    static func identity(_ orientations: [FUInterfaceOrientation]) -> Self {
        Dictionary(orientations.map { ($0, $0) }, uniquingKeysWith: { first, _ in first })
    }
}

internal extension FUInterfaceOrientation {
    /// The edge of the device, in its own portrait, that faces up in this orientation. Turned clockwise, the device's left edge is at the top.
    var upEdge: PhysicalEdge {
        PhysicalEdge.top.rotated(by: rotationFromPortrait)
    }
    
    /// The way the device is held when an edge of it, in its own portrait, faces up.
    init(up edge: PhysicalEdge) {
        self = switch edge {
        case .top: .portrait
        /// Turned clockwise, the device's left edge is at the top.
        case .left: .landscapeRight
        case .bottom: .portraitUpsideDown
        case .right: .landscapeLeft
        }
    }
    
    /// The orientation content presents in this orientation so that its top points to an edge as the user sees it.
    /// - Parameter edge: Where the content's top points as the user sees it: `.top` for upright, `.left` and `.right` for the user's left and right, `.bottom` for upside down.
    func contentOrientation(topAt edge: PhysicalEdge) -> Self {
        /// Holding the device with `edge` up turns it from portrait by the same amount as moving the content's top from the user's top to `edge`.
        rotated(by: Self(up: edge).rotationFromPortrait)
    }
}
#endif
