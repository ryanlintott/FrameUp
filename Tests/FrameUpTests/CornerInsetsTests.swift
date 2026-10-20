//
//  CornerInsetsTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI
import Testing
@testable import FrameUp

struct CornerInsetsTests {
    /// The iPhone Duo's outer screen in portrait, measured: the capsule at top right and rounded corners elsewhere.
    static let duoOuter = PhysicalCornerInsets(
        topLeft: CGSize(width: 8, height: 8),
        topRight: CGSize(width: 84, height: 170),
        bottomLeft: CGSize(width: 8, height: 8),
        bottomRight: CGSize(width: 59, height: 59)
    )

    /// Portrait content in a landscapeLeft interface has the capsule at its top left corner, lying on its side, as measured with reserved regions.
    @Test func duoOuterLandscapeLeft() {
        let expected = PhysicalCornerInsets(
            topLeft: CGSize(width: 170, height: 84),
            topRight: CGSize(width: 59, height: 59),
            bottomLeft: CGSize(width: 8, height: 8),
            bottomRight: CGSize(width: 8, height: 8)
        )
        #expect(Self.duoOuter.rotatedInsets(quarterTurns: 1) == expected)
    }

    @Test func halfTurnKeepsSizes() {
        let expected = PhysicalCornerInsets(
            topLeft: CGSize(width: 59, height: 59),
            topRight: CGSize(width: 8, height: 8),
            bottomLeft: CGSize(width: 84, height: 170),
            bottomRight: CGSize(width: 8, height: 8)
        )
        #expect(Self.duoOuter.rotatedInsets(quarterTurns: 2) == expected)
    }

    @Test(arguments: Array(stride(from: -720.0, through: 720.0, by: 90)))
    func turningBackReturnsTheSameInsets(degrees: Double) {
        let once = Self.duoOuter.rotatedInsets(quarterTurns: Angle.degrees(degrees).quarterTurns)
        #expect(once.rotatedInsets(quarterTurns: Angle.degrees(-degrees).quarterTurns) == Self.duoOuter)
    }
}
