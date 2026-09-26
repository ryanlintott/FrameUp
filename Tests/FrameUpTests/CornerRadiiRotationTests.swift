//
//  CornerRadiiRotationTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI
import Testing
@testable import FrameUp

/// Radii are written as [topLeading, topTrailing, bottomTrailing, bottomLeading], clockwise in left to right.
struct CornerRadiiRotationTests {
    static func radii(_ corners: [CGFloat]) -> FUCorners<CGFloat> {
        FUCorners(topLeading: corners[0], topTrailing: corners[1], bottomLeading: corners[3], bottomTrailing: corners[2])
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
        #expect(Self.radii(Self.corners).rotated(by: .degrees(degrees), layoutDirection: .leftToRight) == Self.radii(expected))
    }

    /// In right to left, leading is on the right, so the same physical rotation moves the named corners the other way.
    @Test(arguments: [
        (0, [1, 2, 3, 4]),
        (90, [4, 1, 2, 3]),
        (180, [3, 4, 1, 2]),
        (-90, [2, 3, 4, 1]),
    ] as [(Double, [CGFloat])])
    func rightToLeft(degrees: Double, expected: [CGFloat]) {
        #expect(Self.radii(Self.corners).rotated(by: .degrees(degrees), layoutDirection: .rightToLeft) == Self.radii(expected))
    }

    /// Portrait content in a landscapeLeft interface puts the capsule's corner (top trailing) at the content's top leading, as measured with reserved regions.
    @Test func duoOuterLandscapeLeft() {
        #expect(Self.radii(Self.duoOuter).rotated(by: .degrees(90), layoutDirection: .leftToRight) == Self.radii([59, 59, 8, 8]))
    }

    @Test(arguments: Array(stride(from: -720.0, through: 720.0, by: 90)))
    func turningBackReturnsTheSameRadii(degrees: Double) {
        let once = Self.radii(Self.corners).rotated(by: .degrees(degrees), layoutDirection: .leftToRight)
        #expect(once.rotated(by: .degrees(-degrees), layoutDirection: .leftToRight) == Self.radii(Self.corners))
    }
    
    @Test func flippingSwapsLeadingAndTrailing() {
        #expect(Self.radii(Self.corners).flippedHorizontally == Self.radii([2, 1, 4, 3]))
        #expect(Self.radii(Self.corners).named(for: .leftToRight) == Self.radii(Self.corners))
        #expect(Self.radii(Self.corners).named(for: .rightToLeft) == Self.radii([2, 1, 4, 3]))
    }
}
