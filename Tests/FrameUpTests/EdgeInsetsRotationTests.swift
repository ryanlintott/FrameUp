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
    
    /// The centre of the inset rect, measured from the centre of the whole rect.
    static func center(_ insets: EdgeInsets) -> CGPoint {
        CGPoint(x: (insets.leading - insets.trailing) / 2, y: (insets.top - insets.bottom) / 2)
    }
    
    /// How far the centre of a rotated set of insets lands from the centre of the insets it was made from, once the rotation has been applied to it.
    static func centerDrift(_ rotated: EdgeInsets, from insets: EdgeInsets, by angle: Angle) -> CGFloat {
        let rotatedCenter = center(rotated)
        let cosine = CGFloat(cos(angle.radians))
        let sine = CGFloat(sin(angle.radians))
        let onScreen = CGPoint(
            x: rotatedCenter.x * cosine - rotatedCenter.y * sine,
            y: rotatedCenter.x * sine + rotatedCenter.y * cosine
        )
        let target = center(insets)
        return hypot(onScreen.x - target.x, onScreen.y - target.y)
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
    
    /// Content is centred in the inset rect, so keeping that centre on the axis of rotation for every angle in a turn is what stops content drifting off axis part way through.
    @Test func theInsetRectCenterFollowsTheRotation() {
        for angle in Self.allAngles {
            let rotated = Self.screenInsets.rotated(by: angle, layoutDirection: .leftToRight)
            #expect(Self.centerDrift(rotated, from: Self.screenInsets, by: angle) < 1e-9, "\(angle.degrees) degrees")
        }
    }
    
    /// A negative inset is not a safe area, and placing the centre exactly can call for more inset on one edge than a pair of opposite insets adds up to.
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
}

struct EdgeInsetsBlendedRotationTests {
    typealias Anchored = EdgeInsetsRotationTests
    
    @Test(arguments: [
        (Angle.degrees(0), EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)),
        (.degrees(90), EdgeInsets(top: 4, leading: 1, bottom: 2, trailing: 3)),
        (.degrees(180), EdgeInsets(top: 3, leading: 4, bottom: 1, trailing: 2)),
        (.degrees(270), EdgeInsets(top: 2, leading: 3, bottom: 4, trailing: 1)),
        (.degrees(-90), EdgeInsets(top: 2, leading: 3, bottom: 4, trailing: 1))
    ])
    func quarterTurns(angle: Angle, expected: EdgeInsets) {
        #expect(Anchored.isApproximatelyEqual(Anchored.insets.rotatedBlendingEdges(by: angle, layoutDirection: .leftToRight), expected))
    }
    
    /// Both rotations move an inset to the same edge at a quarter turn. They only differ in between.
    @Test func matchesTheAnchoredRotationAtEveryQuarterTurn() {
        for degrees in stride(from: -360.0, through: 360.0, by: 90) {
            let angle = Angle.degrees(degrees)
            #expect(Anchored.isApproximatelyEqual(
                Anchored.insets.rotatedBlendingEdges(by: angle, layoutDirection: .leftToRight),
                Anchored.insets.rotated(by: angle, layoutDirection: .leftToRight)
            ), "\(degrees) degrees")
        }
    }
    
    /// Rotation angles accumulate rather than resetting so they can be any number of turns away from zero.
    @Test(arguments: [-720, -450, -360, 360, 450, 720])
    func equivalentAngles(degrees: Double) {
        let equivalent = Angle.degrees(degrees.truncatingRemainder(dividingBy: 360))
        #expect(Anchored.isApproximatelyEqual(
            Anchored.insets.rotatedBlendingEdges(by: .degrees(degrees), layoutDirection: .leftToRight),
            Anchored.insets.rotatedBlendingEdges(by: equivalent, layoutDirection: .leftToRight)
        ))
    }
    
    /// Every inset is a blend of two insets that are themselves never negative.
    @Test func noInsetIsEverNegative() {
        for angle in Anchored.allAngles {
            let rotated = Anchored.screenInsets.rotatedBlendingEdges(by: angle, layoutDirection: .leftToRight)
            #expect(min(rotated.top, rotated.leading, rotated.bottom, rotated.trailing) >= 0, "\(angle.degrees) degrees")
        }
    }
    
    /// A right to left layout mirrors the insets before and after rotating so the result matches an equal rotation in the opposite direction.
    @Test func rightToLeftMirrorsRotation() {
        for angle in Anchored.allAngles {
            #expect(Anchored.isApproximatelyEqual(
                Anchored.insets.rotatedBlendingEdges(by: angle, layoutDirection: .rightToLeft),
                Anchored.insets.rotatedBlendingEdges(by: .degrees(-angle.degrees), layoutDirection: .leftToRight)
            ), "\(angle.degrees) degrees")
        }
    }
    
    /// This is the difference between the two rotations. Blending the edges leaves the centre of the inset rect short of where the rotation puts it, so content centred in that rect drifts off the axis of rotation between quarter turns. The drift is widest halfway between two quarter turns and grows with how lopsided the insets are.
    @Test(arguments: [
        /// An iPhone 17 Pro in portrait.
        (EdgeInsets(top: 62, leading: 0, bottom: 34, trailing: 0), 4.1),
        /// A view under a navigation bar with nothing below it.
        (EdgeInsets(top: 62, leading: 0, bottom: 0, trailing: 0), 9.1),
        /// An iPhone 17 Pro in landscape.
        (EdgeInsets(top: 0, leading: 59, bottom: 21, trailing: 59), 3.1)
    ])
    func blendingEdgesLetsTheCenterDrift(insets: EdgeInsets, expectedDrift: CGFloat) {
        var blended: CGFloat = 0
        var anchored: CGFloat = 0
        
        for angle in Anchored.allAngles {
            blended = max(blended, Anchored.centerDrift(insets.rotatedBlendingEdges(by: angle, layoutDirection: .leftToRight), from: insets, by: angle))
            anchored = max(anchored, Anchored.centerDrift(insets.rotated(by: angle, layoutDirection: .leftToRight), from: insets, by: angle))
        }
        
        #expect(abs(blended - expectedDrift) < 0.05)
        #expect(anchored < 1e-9)
    }
}
