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
    /// Leaves landscape left out, so a move to it falls back to the first allowed orientation.
    let layer = AutoRotatingLayer([.portrait, .landscapeRight, .portraitUpsideDown], isOn: true, counterRotation: .system, animation: nil) { _ in Color.clear }

    /// Unfolding, the content follows the inner interface, not the device, which is a quarter turn off.
    @Test func unfoldingFollowsTheInterface() {
        let before = TurnState(interfaceOrientation: .portrait, contentOrientation: .portrait, screen: .outer, takenTurnID: 1)
        let after = layer.movingToScreen(before, screen: .inner, sceneOrientation: .landscapeRight, deviceOrientation: .portrait)
        #expect(after.screen == .inner)
        #expect(after.interfaceOrientation == .landscapeRight)
        #expect(after.contentOrientation == .landscapeRight)
    }

    /// Folding, the device orientation's entry wins.
    @Test func foldingFollowsTheDevice() {
        let before = TurnState(interfaceOrientation: .landscapeRight, contentOrientation: .landscapeRight, screen: .inner, takenTurnID: 1)
        let after = layer.movingToScreen(before, screen: .outer, sceneOrientation: .portrait, deviceOrientation: .portraitUpsideDown)
        #expect(after.screen == .outer)
        #expect(after.contentOrientation == .portraitUpsideDown)
    }

    /// Folding onto the outer screen held in an orientation the map leaves out, the interface the system picked decides, as in the Top Edges example folded upside down.
    @Test func foldingWithoutADeviceEntryFollowsTheInterface() {
        let before = TurnState(interfaceOrientation: .portrait, contentOrientation: .portrait, screen: .inner, takenTurnID: 1)
        let after = layer.movingToScreen(before, screen: .outer, sceneOrientation: .landscapeRight, deviceOrientation: .landscapeLeft)
        #expect(after.contentOrientation == .landscapeRight)
    }

    /// With no entry for the device or the interface, the content takes the first allowed orientation, as when it appears, not where it was on the other screen.
    @Test func noEntryTakesTheFirstAllowedOrientation() {
        let before = TurnState(interfaceOrientation: .portrait, contentOrientation: .portraitUpsideDown, screen: .outer, takenTurnID: 1)
        let after = layer.movingToScreen(before, screen: .inner, sceneOrientation: .landscapeLeft, deviceOrientation: .portrait)
        #expect(after.contentOrientation == .portrait)
    }

    /// A state that isn't placed yet only takes the screen, and then follows the interface there, not the device.
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
