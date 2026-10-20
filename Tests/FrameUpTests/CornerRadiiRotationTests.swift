//
//  CornerRadiiRotationTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI
import Testing
@testable import FrameUp

/// Radii are written as [topLeft, topRight, bottomRight, bottomLeft], clockwise.
struct CornerRadiiRotationTests {
    static func radii(_ corners: [CGFloat]) -> PhysicalCornerRadii {
        PhysicalCornerRadii(topLeft: corners[0], topRight: corners[1], bottomLeft: corners[3], bottomRight: corners[2])
    }

    static let corners: [CGFloat] = [1, 2, 3, 4]
    /// The iPhone Duo's outer screen in portrait, measured: small corners on the fold side.
    static let duoOuter: [CGFloat] = [8, 59, 59, 8]

    @Test(arguments: [
        (0, [1, 2, 3, 4]),
        (90, [2, 3, 4, 1]),
        (180, [3, 4, 1, 2]),
        (-90, [4, 1, 2, 3]),
        (270, [4, 1, 2, 3]),
    ] as [(Double, [CGFloat])])
    func leftToRight(degrees: Double, expected: [CGFloat]) {
        #expect(Self.radii(Self.corners).rotated(quarterTurns: Angle.degrees(degrees).quarterTurns) == Self.radii(expected))
    }

    /// Portrait content in a landscapeLeft interface puts the capsule's corner (top right) at the content's top left, as measured with reserved regions.
    @Test func duoOuterLandscapeLeft() {
        #expect(Self.radii(Self.duoOuter).rotated(quarterTurns: Angle.degrees(90).quarterTurns) == Self.radii([59, 59, 8, 8]))
    }

    @Test(arguments: Array(stride(from: -720.0, through: 720.0, by: 90)))
    func turningBackReturnsTheSameRadii(degrees: Double) {
        let once = Self.radii(Self.corners).rotated(quarterTurns: Angle.degrees(degrees).quarterTurns)
        #expect(once.rotated(quarterTurns: Angle.degrees(-degrees).quarterTurns) == Self.radii(Self.corners))
    }
    
    /// Leading is on the left in left to right and on the right in right to left.
    @Test func namesFollowLayoutDirection() {
        let corners = PhysicalCornerRadii(topLeading: 1, topTrailing: 2, bottomLeading: 4, bottomTrailing: 3, layoutDirection: .rightToLeft)
        #expect(corners == Self.radii([2, 1, 4, 3]))
        #expect(corners[.topLeading(.rightToLeft)] == 1)
        #expect(corners[.bottomTrailing(.rightToLeft)] == 3)
        #expect(corners[.topLeading(.leftToRight)] == 2)
    }
}
