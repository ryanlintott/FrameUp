//
//  NestedTurnTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

import SwiftUI
import Testing
@testable import FrameUp

/// Content inside a turning `AutoRotatingView` takes the short way round relative to it.
struct NestedTurnTests {
    /// `AutoRotatingView(topEdges:)` on the iPhone Duo's outer screen, from landscape left to portrait. The outer layer holds a portrait frame, and the content inside presents upside down in landscape left and landscape right in portrait, a quarter turn apart on the device.
    @Test func outerLandscapeLeftToPortraitIsAQuarterTurn() {
        let enclosingBefore = FUInterfaceOrientation.portrait.rotation(to: .landscapeLeft)
        let enclosingAfter = FUInterfaceOrientation.portrait.rotation(to: .portrait)
        let before = FUInterfaceOrientation.portraitUpsideDown.rotation(to: .landscapeLeft)
        let target = FUInterfaceOrientation.landscapeRight.rotation(to: .portrait)
        let after = before.closestEquivalent(to: target, enclosingChange: enclosingAfter - enclosingBefore)
        let seenTurn = (after - enclosingAfter) - (before - enclosingBefore)
        #expect(abs(seenTurn.degrees) == 90)
    }

    /// The turn seen inside the enclosing frame is never more than half a turn, and the result is always equivalent to the target.
    @Test(arguments: [-270.0, -180, -90, 0, 90, 180, 270, 450], [-180.0, -90, 0, 90, 180])
    func shortWayRound(current: Double, enclosingChange: Double) {
        for target in stride(from: -360.0, through: 360, by: 90) {
            let result = Angle.degrees(current).closestEquivalent(to: .degrees(target), enclosingChange: .degrees(enclosingChange))
            let seenTurn = result.degrees - enclosingChange - current
            #expect(abs(seenTurn) <= 180)
            #expect((result.degrees - target).truncatingRemainder(dividingBy: 360) == 0)
        }
    }
}
