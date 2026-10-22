//
//  DeviceScreenReportTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-21.
//

#if os(iOS)
import Testing
import SwiftUI
@testable import FrameUp

/// What a view learns about whether the device folds and which screen it's on.
struct DeviceScreenReportTests {
    static func detect(supportsFolding: Bool = true, isSceneOnMainScreen: Bool?, hasVerticalBar: Bool) -> FUFoldability {
        FUFoldability.detect(supportsFolding: supportsFolding, isSceneOnMainScreen: isSceneOnMainScreen, hasVerticalBar: hasVerticalBar)
    }

    /// Before iOS 27.1, and on an iPad, nothing folds, whatever the scene shows.
    @Test(arguments: [true, false, nil] as [Bool?], [true, false])
    func noFoldingSupportIsNotFoldable(isSceneOnMainScreen: Bool?, hasVerticalBar: Bool) {
        let detected = Self.detect(supportsFolding: false, isSceneOnMainScreen: isSceneOnMainScreen, hasVerticalBar: hasVerticalBar)
        #expect(detected == .notFoldable)
    }

    /// Without a window scene there's nothing to go by.
    @Test(arguments: [true, false])
    func noSceneIsUnknown(hasVerticalBar: Bool) {
        let detected = Self.detect(isSceneOnMainScreen: nil, hasVerticalBar: hasVerticalBar)
        #expect(detected == .unknown)
    }

    /// The Duo unfolded: the scene is on the inner screen, with or without the vertical bar (portrait has none).
    @Test(arguments: [true, false])
    func sceneOffTheMainScreenIsTheInnerScreen(hasVerticalBar: Bool) {
        let detected = Self.detect(isSceneOnMainScreen: false, hasVerticalBar: hasVerticalBar)
        #expect(detected == .foldable)
    }

    /// The Duo folded: the outer screen uses the vertical bar in every orientation.
    @Test func verticalBarOnTheMainScreenIsTheOuterScreen() {
        let detected = Self.detect(isSceneOnMainScreen: true, hasVerticalBar: true)
        #expect(detected == .foldable)
    }

    /// Any other iPhone on iOS 27.1.
    @Test func mainScreenWithoutVerticalBarIsNotFoldable() {
        let detected = Self.detect(isSceneOnMainScreen: true, hasVerticalBar: false)
        #expect(detected == .notFoldable)
    }

    /// On a foldable, the main screen is the outer one and the other is the inner one.
    @Test func foldableSceneScreen() {
        #expect(FUDeviceScreen.screen(isFoldable: true, isSceneOnMainScreen: true) == .outer)
        #expect(FUDeviceScreen.screen(isFoldable: true, isSceneOnMainScreen: false) == .inner)
    }

    /// A device that doesn't fold has no screen to report.
    @Test(arguments: [true, false])
    func notFoldableSceneHasNoScreen(isSceneOnMainScreen: Bool) {
        #expect(FUDeviceScreen.screen(isFoldable: false, isSceneOnMainScreen: isSceneOnMainScreen) == nil)
    }

    /// The public property gives what's known about the device.
    @MainActor @Test func isFoldableIsWhatsKnown() {
        #expect(UIDevice.current.isFoldable == (FUFoldability.current == .foldable))
    }

    #if canImport(SwiftUICore, _version: 8.0.85)
    @Test func closedHingeIsTheOuterScreen() throws {
        guard #available(iOS 27.1, *) else { return }
        #expect(FUDeviceScreen(hingeStatus: .closed) == .outer)
    }

    @Test func openHingeIsTheInnerScreen() throws {
        guard #available(iOS 27.1, *) else { return }
        #expect(FUDeviceScreen(hingeStatus: .partiallyOpen) == .inner)
        #expect(FUDeviceScreen(hingeStatus: .fullyOpen) == .inner)
    }

    #endif
}
#endif
