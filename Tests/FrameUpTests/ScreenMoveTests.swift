//
//  ScreenMoveTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-21.
//

#if os(iOS)
import SwiftUI
import Testing
@testable import FrameUp

/// A layer's state moves to the screen of a foldable iPhone its window scene is on.
@MainActor
struct ScreenMoveTests {
    /// Leaves landscape left out, so a move to it falls back to how the device is likely held.
    let layer = AutoRotatingLayer([.portrait, .landscapeRight, .portraitUpsideDown], isOn: true, counterRotation: .system, animation: nil) { _ in Color.clear }

    /// Unfolding, the guide to how the device is held is the device orientation on the outer screen, not the interface's, which can be locked.
    @Test func unfoldingFollowsTheDeviceOrientationOnTheOuterScreen() {
        let before = TurnState(interfaceOrientation: .portrait, contentOrientation: .portrait, screen: .outer, takenTurnID: 1)
        let after = layer.movingToScreen(before, screen: .inner, sceneOrientation: .landscapeLeft, deviceOrientation: .landscapeRight)
        #expect(after.screen == .inner)
        #expect(after.interfaceOrientation == .landscapeLeft)
        #expect(after.contentOrientation == .portraitUpsideDown)
    }

    /// Folding, the guide is the interface orientation on the inner screen.
    @Test func foldingFollowsTheInterfaceOrientationOnTheInnerScreen() {
        let before = TurnState(interfaceOrientation: .landscapeLeft, contentOrientation: .landscapeRight, screen: .inner, takenTurnID: 1)
        let after = layer.movingToScreen(before, screen: .outer, sceneOrientation: .portrait, deviceOrientation: nil)
        #expect(after.screen == .outer)
        #expect(after.interfaceOrientation == .portrait)
        #expect(after.contentOrientation == .portrait)
    }

    /// A state that isn't placed yet only takes the screen, and then follows the interface there, not the device, which is a quarter turn off.
    @Test func appearingOnTheInnerScreenFollowsTheInterface() {
        let moved = layer.movingToScreen(TurnState(), screen: .inner, sceneOrientation: .landscapeRight, deviceOrientation: .portraitUpsideDown)
        #expect(moved == TurnState(screen: .inner))
        let placed = layer.updatingOrientations(moved, interfaceOrientation: .landscapeRight, deviceOrientation: .portraitUpsideDown)
        #expect(placed.contentOrientation == .landscapeRight)
    }

    /// A state already on the scene's screen stays as it is.
    @Test func sameScreenKeepsTheState() {
        let before = TurnState(interfaceOrientation: .landscapeLeft, contentOrientation: .landscapeRight, screen: .inner, takenTurnID: 1)
        #expect(layer.movingToScreen(before, screen: .inner, sceneOrientation: .portrait, deviceOrientation: .portrait) == before)
    }
}
#endif
