//
//  ContentRotationTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-11.
//

import CoreGraphics
import SwiftUI
import Testing
@testable import FrameUp

/// The size an `AutoRotatingView` gives its content is the container seen from inside the rotation.
struct CGSizeRotationTests {
    /// An iPhone 17 Pro in portrait.
    static let container = CGSize(width: 402, height: 874)
    static let swapped = CGSize(width: 874, height: 402)

    @Test(arguments: [
        (Angle.degrees(0), container),
        (.degrees(90), swapped),
        (.degrees(180), container),
        (.degrees(270), swapped),
        (.degrees(-90), swapped)
    ])
    func quarterTurnsSwapWidthAndHeight(angle: Angle, expected: CGSize) {
        #expect(Self.container.rotated(by: angle) == expected)
    }

    /// Rotation angles accumulate rather than resetting so they can be any number of turns away from zero.
    @Test(arguments: [-720.0, -450, -360, 360, 450, 720])
    func equivalentAngles(degrees: Double) {
        let equivalent = Angle.degrees(degrees.truncatingRemainder(dividingBy: 360))
        #expect(Self.container.rotated(by: .degrees(degrees)) == Self.container.rotated(by: equivalent))
    }

    /// Angles that are not quarter turns are matched to the nearest one.
    @Test(arguments: [46.0, 89.0, 90.0, 91.0, 134.0])
    func nearestQuarterTurn(degrees: Double) {
        #expect(Self.container.rotated(by: .degrees(degrees)) == Self.swapped)
    }
}

/// Content rotation accumulates so an animated turn always takes the shortest path.
struct AngleClosestEquivalentTests {
    /// Angles from two full turns one way to two full turns the other, none of them landing on a quarter turn.
    static let allAngles = Array(stride(from: -720.0, through: 720, by: 7))

    @Test(arguments: [
        /// A quarter turn back from portrait is shorter than three quarters forward.
        (Angle.degrees(270), Angle.degrees(0), Angle.degrees(360)),
        /// Landscape to upside down is a quarter turn either way. Turning the way the angle is already going keeps it accumulating.
        (.degrees(-90), .degrees(180), .degrees(-180)),
        (.degrees(90), .degrees(180), .degrees(180)),
        /// An angle already at its target does not move.
        (.degrees(720), .degrees(0), .degrees(720))
    ])
    func theShortestPathIsTaken(angle: Angle, target: Angle, expected: Angle) {
        #expect(abs(angle.closestEquivalent(to: target).degrees - expected.degrees) < 1e-9)
    }

    /// The result is always the target orientation, and never more than a half turn away from where the content already is.
    @Test(arguments: allAngles)
    func theResultIsEquivalentAndNoMoreThanAHalfTurnAway(degrees: Double) {
        let angle = Angle.degrees(degrees)

        for target in [Angle.degrees(0), .degrees(90), .degrees(180), .degrees(270)] {
            let equivalent = angle.closestEquivalent(to: target)
            #expect(abs(equivalent.degrees - angle.degrees) <= 180 + 1e-9, "\(degrees) to \(target.degrees)")
            #expect(abs((equivalent.degrees - target.degrees).remainder(dividingBy: 360)) < 1e-9, "\(degrees) to \(target.degrees)")
        }
    }
}
