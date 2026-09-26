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
    static let insets = EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)
    /// An iPhone 17 Pro in portrait.
    static let screenInsets = EdgeInsets(top: 62, leading: 0, bottom: 34, trailing: 0)
    /// Every angle from a full turn one way to a full turn the other, in single degree steps.
    static let allAngles = stride(from: -360.0, through: 360.0, by: 1).map(Angle.degrees)
    
    static func isApproximatelyEqual(_ a: EdgeInsets, _ b: EdgeInsets) -> Bool {
        let tolerance: CGFloat = 1e-9
        return abs(a.top - b.top) < tolerance
        && abs(a.leading - b.leading) < tolerance
        && abs(a.bottom - b.bottom) < tolerance
        && abs(a.trailing - b.trailing) < tolerance
    }
    
    @Test(arguments: [
        (Angle.degrees(0), EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)),
        (.degrees(90), EdgeInsets(top: 4, leading: 1, bottom: 2, trailing: 3)),
        (.degrees(180), EdgeInsets(top: 3, leading: 4, bottom: 1, trailing: 2)),
        (.degrees(270), EdgeInsets(top: 2, leading: 3, bottom: 4, trailing: 1)),
        (.degrees(-90), EdgeInsets(top: 2, leading: 3, bottom: 4, trailing: 1))
    ])
    func quarterTurns(angle: Angle, expected: EdgeInsets) {
        #expect(Self.isApproximatelyEqual(Self.insets.rotated(by: angle, layoutDirection: .leftToRight), expected))
    }
    
    /// Rotation angles accumulate rather than resetting so they can be any number of turns away from zero.
    @Test(arguments: [-720, -450, -360, 360, 450, 720])
    func equivalentAngles(degrees: Double) {
        let equivalent = Angle.degrees(degrees.truncatingRemainder(dividingBy: 360))
        #expect(Self.isApproximatelyEqual(
            Self.insets.rotated(by: .degrees(degrees), layoutDirection: .leftToRight),
            Self.insets.rotated(by: equivalent, layoutDirection: .leftToRight)
        ))
    }
    
    /// Angles that are not quarter turns are matched to the nearest one.
    @Test(arguments: [46.0, 89.0, 90.0, 91.0, 134.0])
    func nearestQuarterTurn(degrees: Double) {
        #expect(Self.isApproximatelyEqual(
            Self.insets.rotated(by: .degrees(degrees), layoutDirection: .leftToRight),
            Self.insets.rotated(by: .degrees(90), layoutDirection: .leftToRight)
        ))
    }
    
    /// Every inset is one of the insets it started as, so none of them can be anything a safe area is not.
    @Test func noInsetIsEverNegative() {
        for angle in Self.allAngles {
            let rotated = Self.screenInsets.rotated(by: angle, layoutDirection: .leftToRight)
            #expect(min(rotated.top, rotated.leading, rotated.bottom, rotated.trailing) >= 0, "\(angle.degrees) degrees")
        }
    }
    
    /// A right to left layout mirrors the insets before and after rotating so the result matches an equal rotation in the opposite direction.
    @Test func rightToLeftMirrorsRotation() {
        for angle in Self.allAngles {
            #expect(Self.isApproximatelyEqual(
                Self.insets.rotated(by: angle, layoutDirection: .rightToLeft),
                Self.insets.rotated(by: .degrees(-angle.degrees), layoutDirection: .leftToRight)
            ), "\(angle.degrees) degrees")
        }
    }

    /// Converting right to left insets to screen directions, rotating left to right, and converting back gives the same insets as rotating right to left. `AutoRotatingView` relies on this, since it lays out its rotation left to right.
    @Test func rotatingOnScreenMatchesRightToLeft() {
        for angle in Self.allAngles {
            #expect(Self.isApproximatelyEqual(
                Self.insets.flippedHorizontally.rotated(by: angle, layoutDirection: .leftToRight).flippedHorizontally,
                Self.insets.rotated(by: angle, layoutDirection: .rightToLeft)
            ), "\(angle.degrees) degrees")
        }
    }
}
