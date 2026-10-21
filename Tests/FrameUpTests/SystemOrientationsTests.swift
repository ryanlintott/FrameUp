//
//  SystemOrientationsTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-20.
//

#if os(iOS)
import Testing
import UIKit
@testable import FrameUp

/// The system turns a window only to orientations both the app and the view controller at its top support.
@MainActor
struct SystemOrientationsTests {
    final class RestrictedViewController: UIViewController {
        var mask: UIInterfaceOrientationMask = .portrait
        override var supportedInterfaceOrientations: UIInterfaceOrientationMask { mask }
    }

    @Test func masksMatchUIKitNames() {
        #expect(FUInterfaceOrientation.landscapeRight.mask == .landscapeLeft)
        #expect(FUInterfaceOrientation.landscapeLeft.mask == .landscapeRight)
        #expect(FUInterfaceOrientation.allCases.reduce(into: UIInterfaceOrientationMask()) { $0.formUnion($1.mask) } == .all)
    }

    @Test func viewControllerLimitsTheAppsOrientations() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 600))
        let viewController = RestrictedViewController()
        viewController.mask = [.portrait, .landscapeRight]
        window.rootViewController = viewController
        let app = FUInterfaceOrientation.systemOrientations(in: nil)
        let isMultitasking = FUInterfaceOrientation.isMultitasking(
            idiom: UIDevice.current.userInterfaceIdiom,
            requiresFullScreen: Bundle.main.object(forInfoDictionaryKey: "UIRequiresFullScreen") as? Bool == true,
            infoPlistOrientations: UIApplication.shared.supportedInterfaceOrientations(for: nil)
        )
        let expected = isMultitasking ? app : app.filter { [.portrait, .landscapeLeft].contains($0) }
        #expect(FUInterfaceOrientation.systemOrientations(in: window) == expected)
        #expect(window.topFullScreenViewController === viewController)
    }

    /// An iPad app multitasks, and the system ignores its view controllers, unless it requires the full screen or leaves an orientation out of its Info.plist.
    @Test func multitaskingFollowsAppleRules() {
        #expect(FUInterfaceOrientation.isMultitasking(idiom: .pad, requiresFullScreen: false, infoPlistOrientations: .all))
        #expect(!FUInterfaceOrientation.isMultitasking(idiom: .pad, requiresFullScreen: true, infoPlistOrientations: .all))
        #expect(!FUInterfaceOrientation.isMultitasking(idiom: .pad, requiresFullScreen: false, infoPlistOrientations: .allButUpsideDown))
        #expect(!FUInterfaceOrientation.isMultitasking(idiom: .phone, requiresFullScreen: false, infoPlistOrientations: .all))
    }

    /// The scene has already turned when the coordinator reports the turn, so it's the new orientation as it is, not turned again.
    @Test func newOrientationAfterSystemTurn() {
        #expect(FUInterfaceOrientation.afterSystemTurn(by: .degrees90, from: .portrait, sceneOrientation: .landscapeLeft) == .landscapeLeft)
        #expect(FUInterfaceOrientation.afterSystemTurn(by: .degrees270, from: .portrait, sceneOrientation: nil) == .landscapeRight)
        #expect(FUInterfaceOrientation.afterSystemTurn(by: .degrees90, from: nil, sceneOrientation: .landscapeLeft) == .landscapeLeft)
    }
}
#endif
