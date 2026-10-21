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
        let expected = app.filter { [.portrait, .landscapeLeft].contains($0) }
        if UIDevice.current.userInterfaceIdiom == .phone {
            #expect(FUInterfaceOrientation.systemOrientations(in: window) == expected)
        }
        #expect(window.topFullScreenViewController === viewController)
    }
}
#endif
