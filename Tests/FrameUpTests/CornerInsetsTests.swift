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
    /// The iPhone Duo's outer screen in portrait, measured: the capsule at top trailing and rounded corners elsewhere.
    static let duoOuter = FUCorners(
        topLeading: CGSize(width: 8, height: 8),
        topTrailing: CGSize(width: 84, height: 170),
        bottomLeading: CGSize(width: 8, height: 8),
        bottomTrailing: CGSize(width: 59, height: 59)
    )

    /// Portrait content in a landscapeLeft interface has the capsule at its top leading corner, lying on its side, as measured with reserved regions.
    @Test func duoOuterLandscapeLeft() {
        let expected = FUCorners(
            topLeading: CGSize(width: 170, height: 84),
            topTrailing: CGSize(width: 59, height: 59),
            bottomLeading: CGSize(width: 8, height: 8),
            bottomTrailing: CGSize(width: 8, height: 8)
        )
        #expect(Self.duoOuter.rotatedInsets(by: .degrees(90), layoutDirection: .leftToRight) == expected)
    }

    @Test func halfTurnKeepsSizes() {
        let expected = FUCorners(
            topLeading: CGSize(width: 59, height: 59),
            topTrailing: CGSize(width: 8, height: 8),
            bottomLeading: CGSize(width: 84, height: 170),
            bottomTrailing: CGSize(width: 8, height: 8)
        )
        #expect(Self.duoOuter.rotatedInsets(by: .degrees(180), layoutDirection: .leftToRight) == expected)
    }

    @Test(arguments: Array(stride(from: -720.0, through: 720.0, by: 90)))
    func turningBackReturnsTheSameInsets(degrees: Double) {
        let once = Self.duoOuter.rotatedInsets(by: .degrees(degrees), layoutDirection: .leftToRight)
        #expect(once.rotatedInsets(by: .degrees(-degrees), layoutDirection: .leftToRight) == Self.duoOuter)
    }
}
