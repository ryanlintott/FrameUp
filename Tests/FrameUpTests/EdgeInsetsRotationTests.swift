//
//  EdgeInsetsRotationTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-10.
//

import CoreGraphics
import SwiftUI
import Testing
@testable import FrameUp

struct EdgeInsetsRotationTests {
    static let insets = PhysicalEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
    /// An iPhone 17 Pro in portrait.
    static let screenInsets = PhysicalEdgeInsets(top: 62, left: 0, bottom: 34, right: 0)
    /// Every angle from a full turn one way to a full turn the other, in single degree steps.
    static let allAngles = stride(from: -360.0, through: 360.0, by: 1).map(Angle.degrees)
    
    static func isApproximatelyEqual(_ a: PhysicalEdgeInsets, _ b: PhysicalEdgeInsets) -> Bool {
        let tolerance: CGFloat = 1e-9
        return abs(a.top - b.top) < tolerance
        && abs(a.left - b.left) < tolerance
        && abs(a.bottom - b.bottom) < tolerance
        && abs(a.right - b.right) < tolerance
    }
    
    @Test(arguments: [
        (Angle.degrees(0), PhysicalEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)),
        (.degrees(90), PhysicalEdgeInsets(top: 4, left: 1, bottom: 2, right: 3)),
        (.degrees(180), PhysicalEdgeInsets(top: 3, left: 4, bottom: 1, right: 2)),
        (.degrees(270), PhysicalEdgeInsets(top: 2, left: 3, bottom: 4, right: 1)),
        (.degrees(-90), PhysicalEdgeInsets(top: 2, left: 3, bottom: 4, right: 1))
    ])
    func quarterTurns(angle: Angle, expected: PhysicalEdgeInsets) {
        #expect(Self.isApproximatelyEqual(Self.insets.rotated(quarterTurns: angle.quarterTurns), expected))
    }
    
    /// Rotation angles accumulate rather than resetting so they can be any number of turns away from zero.
    @Test(arguments: [-720, -450, -360, 360, 450, 720])
    func equivalentAngles(degrees: Double) {
        let equivalent = Angle.degrees(degrees.truncatingRemainder(dividingBy: 360))
        #expect(Self.isApproximatelyEqual(
            Self.insets.rotated(quarterTurns: Angle.degrees(degrees).quarterTurns),
            Self.insets.rotated(quarterTurns: equivalent.quarterTurns)
        ))
    }
    
    /// Angles that are not quarter turns are matched to the nearest one.
    @Test(arguments: [46.0, 89.0, 90.0, 91.0, 134.0])
    func nearestQuarterTurn(degrees: Double) {
        #expect(Self.isApproximatelyEqual(
            Self.insets.rotated(quarterTurns: Angle.degrees(degrees).quarterTurns),
            Self.insets.rotated(quarterTurns: Angle.degrees(90).quarterTurns)
        ))
    }
    
    /// Every inset is one of the insets it started as, so none of them can be anything a safe area is not.
    @Test func noInsetIsEverNegative() {
        for angle in Self.allAngles {
            let rotated = Self.screenInsets.rotated(quarterTurns: angle.quarterTurns)
            #expect(min(rotated.top, rotated.left, rotated.bottom, rotated.right) >= 0, "\(angle.degrees) degrees")
        }
    }
    
    /// Leading is on the left in left to right and on the right in right to left.
    @Test func namesFollowLayoutDirection() {
        let named = EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)
        #expect(PhysicalEdgeInsets(named, layoutDirection: .leftToRight) == PhysicalEdgeInsets(top: 1, left: 2, bottom: 3, right: 4))
        #expect(PhysicalEdgeInsets(named, layoutDirection: .rightToLeft) == PhysicalEdgeInsets(top: 1, left: 4, bottom: 3, right: 2))
        for direction in [LayoutDirection.leftToRight, .rightToLeft] {
            #expect(PhysicalEdgeInsets(named, layoutDirection: direction).edgeInsets(layoutDirection: direction) == named)
        }
    }
}
