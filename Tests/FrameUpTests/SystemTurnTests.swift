//
//  SystemTurnTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-20.
//

#if os(iOS)
import SwiftUI
import Testing
@testable import FrameUp

/// A `.system` layer's orientations change when the device turns, and the system's turn carries the change.
@MainActor
struct SystemTurnTests {
    let layer = AutoRotatingLayer([.portrait, .landscapeRight, .portraitUpsideDown], isOn: true, counterRotation: .system, animation: nil) { _ in Color.clear }

    func systemTurn(id: Int, from: FUInterfaceOrientation, to: FUInterfaceOrientation) -> AutoRotatingTurn {
        AutoRotatingTurn(id: id, kind: .system(angle: to.rotation(from: from).angle, timing: SystemTurnTiming(duration: 0.3)), interfaceOrientation: to, animation: nil)
    }

    /// When the device's notification arrives after the system's turn has started, the system's turn changes the orientations.
    @Test func systemTurnBeforeDeviceTurnChangesOrientations() {
        let before = TurnState(interfaceOrientation: .portrait, contentOrientation: .portrait, contentRotation: .zero, turnStart: nil, screen: .outer, takenTurnID: 1)
        let after = layer.taking(systemTurn(id: 2, from: .portrait, to: .landscapeRight), from: before)
        #expect(after.interfaceOrientation == .landscapeRight)
        #expect(after.turnStart == nil)
        #expect(after.takenTurnID == 2)
        let contentOrientation = try! #require(after.contentOrientation)
        #expect((after.contentRotation - contentOrientation.rotation(from: .landscapeRight).angle).degrees.truncatingRemainder(dividingBy: 360) == 0)
    }

    /// After the device's turn, the system's turn to the same orientation leaves the orientations as they are.
    @Test func systemTurnAfterDeviceTurnKeepsOrientations() {
        let before = TurnState(interfaceOrientation: .landscapeRight, contentOrientation: .landscapeRight, contentRotation: .zero, turnStart: nil, screen: .outer, takenTurnID: 1)
        var expected = before
        expected.takenTurnID = 2
        #expect(layer.taking(systemTurn(id: 2, from: .portrait, to: .landscapeRight), from: before) == expected)
    }
}
#endif
