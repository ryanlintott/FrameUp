//
//  NestedTurnTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

#if os(iOS)
import SwiftUI
import Testing
@testable import FrameUp

/// Content inside a turning `AutoRotatingView` turns relative to it, on the same progress.
struct NestedTurnTests {
    /// `AutoRotatingView(topEdges:)` on the iPhone Duo's outer screen, from landscape left to portrait. The outer layer holds a portrait frame, and the content inside presents upside down in landscape left and landscape right in portrait, a quarter turn apart on the device.
    @Test func outerLandscapeLeftToPortraitIsAQuarterTurn() {
        let outerBefore = FUInterfaceOrientation.portrait.rotation(from: .landscapeLeft).angle
        let outer = LayerTurn(enclosing: ContentRotation(), start: outerBefore, target: outerBefore - FUInterfaceOrientation.landscapeLeft.rotation(from: .portrait).angle, isShortWay: false)
        let before = FUInterfaceOrientation.portraitUpsideDown.rotation(from: .landscapeLeft).angle
        let target = before.closestEquivalent(to: FUInterfaceOrientation.landscapeRight.rotation(from: .portrait).angle)
        let inner = LayerTurn(enclosing: outer.contentRotation, start: before, target: target, isShortWay: true)
        #expect(abs(inner.rotationChange.degrees) == 90)
    }

    /// The turn seen inside the enclosing frame is never more than half a turn, and the content ends at its target.
    @Test(arguments: [-270.0, -180, -90, 0, 90, 180, 270, 450], [-180.0, -90, 0, 90, 180])
    func shortWayRound(current: Double, enclosingChange: Double) {
        let enclosing = ContentRotation(startRotation: .zero, rotationChange: .degrees(enclosingChange))
        for target in stride(from: -360.0, through: 360, by: 90) {
            let turn = LayerTurn(enclosing: enclosing, start: .degrees(current), target: .degrees(target), isShortWay: true)
            #expect(abs(turn.rotationChange.degrees) <= 180)
            #expect((turn.contentRotation.startRotation + turn.contentRotation.rotationChange - .degrees(target)).degrees.truncatingRemainder(dividingBy: 360) == 0)
        }
    }

    /// Content held still turns back by exactly as much as the interface turns, however far the content around it turns.
    @Test(arguments: [-180.0, -90, 90, 180], [-180.0, -90, 0, 90, 180, 270])
    func heldStillTurnsBackExactly(angle: Double, enclosingChange: Double) {
        let enclosing = ContentRotation(startRotation: .degrees(30), rotationChange: .degrees(enclosingChange))
        let turn = LayerTurn(enclosing: enclosing, start: .degrees(90), target: .degrees(90 - angle), isShortWay: false)
        #expect(turn.contentRotation.rotationChange.degrees == -angle)
        #expect(turn.rotationChange.degrees == -angle - enclosingChange)
    }

    /// At the end of a turn the content is exactly at its target, and at the start exactly where it was.
    @Test func endsExactly() {
        let turn = LayerTurn(enclosing: ContentRotation(startRotation: .degrees(-90), rotationChange: .degrees(90)), start: .degrees(17), target: .degrees(-163), isShortWay: true)
        #expect(turn.rotation(progress: 0) == turn.startRotation)
        #expect(turn.rotation(progress: 1) == turn.targetRotation)
        #expect(turn.rotation(progress: 0.5) == turn.startRotation + .degrees(turn.rotationChange.degrees / 2))
        let start = LayerFrame(size: CGSize(width: 402.3, height: 874.1), safeAreaInsets: PhysicalEdgeInsets(top: 62.3, bottom: 34.1))
        let end = LayerFrame(size: CGSize(width: 874.1, height: 402.3), safeAreaInsets: PhysicalEdgeInsets(left: 62.3, bottom: 21, right: 62.3))
        #expect(start.interpolated(to: end, progress: 0) == start)
        #expect(start.interpolated(to: end, progress: 1) == end)
    }
}
#endif
