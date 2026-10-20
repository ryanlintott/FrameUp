//
//  PhysicalEdgeTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-20.
//

import SwiftUI
import Testing
@testable import FrameUp

struct PhysicalEdgeTests {
    @Test(arguments: [
        (PhysicalEdge.top, 1, PhysicalEdge.right),
        (.right, 1, .bottom),
        (.left, 1, .top),
        (.top, 2, .bottom),
        (.top, -1, .left),
        (.top, 5, .right),
        (.top, -5, .left)
    ])
    func rotatesClockwise(edge: PhysicalEdge, quarterTurns: Int, expected: PhysicalEdge) {
        #expect(edge.rotated(quarterTurns: quarterTurns) == expected)
    }

    /// Leading is on the left in left to right and on the right in right to left.
    @Test(arguments: [
        (Edge.leading, LayoutDirection.leftToRight, PhysicalEdge.left),
        (.trailing, .leftToRight, .right),
        (.leading, .rightToLeft, .right),
        (.trailing, .rightToLeft, .left),
        (.top, .rightToLeft, .top),
        (.bottom, .leftToRight, .bottom)
    ])
    func namesFollowLayoutDirection(edge: Edge, layoutDirection: LayoutDirection, expected: PhysicalEdge) {
        #expect(PhysicalEdge(edge, layoutDirection: layoutDirection) == expected)
        #expect(expected.edge(layoutDirection: layoutDirection) == edge)
    }
}

struct PhysicalCornerTests {
    @Test(arguments: [
        (PhysicalCorner.topLeft, 1, PhysicalCorner.topRight),
        (.topRight, 1, .bottomRight),
        (.bottomLeft, 1, .topLeft),
        (.topLeft, 2, .bottomRight),
        (.topLeft, -1, .bottomLeft),
        (.topLeft, -5, .bottomLeft)
    ])
    func rotatesClockwise(corner: PhysicalCorner, quarterTurns: Int, expected: PhysicalCorner) {
        #expect(corner.rotated(quarterTurns: quarterTurns) == expected)
    }

    /// Leading is on the left in left to right and on the right in right to left.
    @Test func namesFollowLayoutDirection() {
        #expect(PhysicalCorner.topLeading(.leftToRight) == .topLeft)
        #expect(PhysicalCorner.topLeading(.rightToLeft) == .topRight)
        #expect(PhysicalCorner.bottomTrailing(.leftToRight) == .bottomRight)
        #expect(PhysicalCorner.bottomTrailing(.rightToLeft) == .bottomLeft)
    }
}
