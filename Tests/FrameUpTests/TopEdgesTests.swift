//
//  TopEdgesTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

import SwiftUI
import Testing
@testable import FrameUp

/// `AutoRotatingView(topEdges:)` takes where the content's top points as the user sees it, and presents the orientation that puts it there.
struct TopEdgesTests {
    /// The edge of the device that faces up in each orientation. Landscape right is the device turned clockwise, so its left edge is at the top.
    @Test(arguments: [
        (FUInterfaceOrientation.portrait, Edge.top),
        (.landscapeRight, .leading),
        (.landscapeLeft, .trailing),
        (.portraitUpsideDown, .bottom)
    ])
    func upEdge(orientation: FUInterfaceOrientation, expected: Edge) {
        #expect(orientation.upEdge == expected)
        #expect(FUInterfaceOrientation(up: expected) == orientation)
    }

    /// Upright content presents the orientation the device is in.
    @Test(arguments: FUInterfaceOrientation.allCases)
    func topIsUpright(orientation: FUInterfaceOrientation) {
        #expect(orientation.presenting(up: .top) == orientation)
    }

    /// Upside-down content presents the opposite orientation.
    @Test(arguments: [
        (FUInterfaceOrientation.portrait, FUInterfaceOrientation.portraitUpsideDown),
        (.landscapeRight, .landscapeLeft),
        (.landscapeLeft, .landscapeRight),
        (.portraitUpsideDown, .portrait)
    ])
    func bottomIsUpsideDown(orientation: FUInterfaceOrientation, expected: FUInterfaceOrientation) {
        #expect(orientation.presenting(up: .bottom) == expected)
    }

    /// Content that stays fixed to the device in portrait: in landscape right, turned clockwise, the device's top is on the user's right, and in landscape left on the user's left.
    @Test(arguments: [
        (FUInterfaceOrientation.portrait, Edge.top),
        (.landscapeRight, .trailing),
        (.landscapeLeft, .leading),
        (.portraitUpsideDown, .bottom)
    ])
    func fixedToDevicePresentsPortrait(orientation: FUInterfaceOrientation, up: Edge) {
        #expect(orientation.presenting(up: up) == .portrait)
    }

    /// In portrait the device's edges are the user's, so content whose top points left presents landscape right, as when the device is turned clockwise.
    @Test(arguments: [
        (Edge.leading, FUInterfaceOrientation.landscapeRight),
        (.trailing, .landscapeLeft)
    ])
    func sidewaysInPortrait(up: Edge, expected: FUInterfaceOrientation) {
        #expect(FUInterfaceOrientation.portrait.presenting(up: up) == expected)
    }

    /// The content's top ends up on the device edge that's that way from the user, for every orientation and edge.
    @Test(arguments: FUInterfaceOrientation.allCases, [Edge.top, .trailing, .bottom, .leading])
    func topFacesTheChosenWay(orientation: FUInterfaceOrientation, up: Edge) {
        let presented = orientation.presenting(up: up)
        /// The quarter turns clockwise from the user's up to the chosen edge equal those from the device edge at the top to the device edge the content's top faces.
        let clockwise: [Edge] = [.top, .trailing, .bottom, .leading]
        let turnsToEdge = clockwise.firstIndex(of: up)!
        let turnsOnDevice = (clockwise.firstIndex(of: presented.upEdge)! - clockwise.firstIndex(of: orientation.upEdge)! + 4) % 4
        #expect(turnsOnDevice == turnsToEdge)
    }

    /// The orientation map for the example's set: upright in either portrait, top to the user's left in either landscape. In landscape right the user's left is the device's bottom edge, and in landscape left its top edge.
    @Test func orientationMap() {
        let topEdges: [FUInterfaceOrientation: Edge] = [
            .portrait: .top,
            .landscapeRight: .leading,
            .landscapeLeft: .leading,
            .portraitUpsideDown: .top
        ]
        #expect([FUInterfaceOrientation: FUInterfaceOrientation].presenting(topEdges: topEdges, layoutDirection: .leftToRight) == [
            .portrait: .portrait,
            .landscapeRight: .portraitUpsideDown,
            .landscapeLeft: .portrait,
            .portraitUpsideDown: .portraitUpsideDown
        ])
    }

    /// Edges are layout-relative: in a right-to-left layout leading is the user's right.
    @Test func rightToLeftFlipsLeadingAndTrailing() {
        let topEdges: [FUInterfaceOrientation: Edge] = [.landscapeRight: .leading, .landscapeLeft: .trailing, .portrait: .top]
        let leftToRight = [FUInterfaceOrientation: FUInterfaceOrientation].presenting(topEdges: topEdges, layoutDirection: .leftToRight)
        let rightToLeft = [FUInterfaceOrientation: FUInterfaceOrientation].presenting(topEdges: topEdges, layoutDirection: .rightToLeft)
        #expect(leftToRight == [.landscapeRight: .portraitUpsideDown, .landscapeLeft: .portraitUpsideDown, .portrait: .portrait])
        #expect(rightToLeft == [.landscapeRight: .portrait, .landscapeLeft: .portrait, .portrait: .portrait])
    }
}
