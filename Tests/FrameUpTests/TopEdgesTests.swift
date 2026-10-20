//
//  TopEdgesTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

#if os(iOS)
import SwiftUI
import Testing
@testable import FrameUp

/// `AutoRotatingView(topEdges:)` takes where the content's top points as the user sees it, and presents the orientation that puts it there.
struct TopEdgesTests {
    /// The edge of the device that faces up in each orientation. Landscape right is the device turned clockwise, so its left edge is at the top.
    @Test(arguments: [
        (FUInterfaceOrientation.portrait, PhysicalEdge.top),
        (.landscapeRight, .left),
        (.landscapeLeft, .right),
        (.portraitUpsideDown, .bottom)
    ])
    func upEdge(orientation: FUInterfaceOrientation, expected: PhysicalEdge) {
        #expect(orientation.upEdge == expected)
        #expect(FUInterfaceOrientation(up: expected) == orientation)
    }

    /// Upright content presents the orientation the device is in.
    @Test(arguments: FUInterfaceOrientation.allCases)
    func topIsUpright(orientation: FUInterfaceOrientation) {
        #expect(orientation.contentOrientation(topAt: .top) == orientation)
    }

    /// Upside-down content presents the opposite orientation.
    @Test(arguments: [
        (FUInterfaceOrientation.portrait, FUInterfaceOrientation.portraitUpsideDown),
        (.landscapeRight, .landscapeLeft),
        (.landscapeLeft, .landscapeRight),
        (.portraitUpsideDown, .portrait)
    ])
    func bottomIsUpsideDown(orientation: FUInterfaceOrientation, expected: FUInterfaceOrientation) {
        #expect(orientation.contentOrientation(topAt: .bottom) == expected)
    }

    /// Content that stays fixed to the device in portrait: in landscape right, turned clockwise, the device's top is on the user's right, and in landscape left on the user's left.
    @Test(arguments: [
        (FUInterfaceOrientation.portrait, PhysicalEdge.top),
        (.landscapeRight, .right),
        (.landscapeLeft, .left),
        (.portraitUpsideDown, .bottom)
    ])
    func fixedToDevicePresentsPortrait(orientation: FUInterfaceOrientation, up: PhysicalEdge) {
        #expect(orientation.contentOrientation(topAt: up) == .portrait)
    }

    /// In portrait the device's edges are the user's, so content whose top points left presents landscape right, as when the device is turned clockwise.
    @Test(arguments: [
        (PhysicalEdge.left, FUInterfaceOrientation.landscapeRight),
        (.right, .landscapeLeft)
    ])
    func sidewaysInPortrait(up: PhysicalEdge, expected: FUInterfaceOrientation) {
        #expect(FUInterfaceOrientation.portrait.contentOrientation(topAt: up) == expected)
    }

    /// The content's top ends up on the device edge that's that way from the user, for every orientation and edge.
    @Test(arguments: FUInterfaceOrientation.allCases, PhysicalEdge.allCases)
    func topFacesTheChosenWay(orientation: FUInterfaceOrientation, up: PhysicalEdge) {
        let presented = orientation.contentOrientation(topAt: up)
        /// The quarter turns clockwise from the user's up to the chosen edge equal those from the device edge at the top to the device edge the content's top faces.
        #expect(presented.rotation(from: orientation) == FUInterfaceOrientation(up: up).rotation(from: .portrait))
    }

    /// The orientation map for the example's set: upright in either portrait, top to the user's left in either landscape. In landscape right the user's left is the device's bottom edge, and in landscape left its top edge.
    @Test func orientationMap() {
        let topEdges: [FUInterfaceOrientation: Edge] = [
            .portrait: .top,
            .landscapeRight: .leading,
            .landscapeLeft: .leading,
            .portraitUpsideDown: .top
        ]
        #expect([FUInterfaceOrientation: FUInterfaceOrientation].contentOrientations(topEdges: topEdges, layoutDirection: .leftToRight) == [
            .portrait: .portrait,
            .landscapeRight: .portraitUpsideDown,
            .landscapeLeft: .portrait,
            .portraitUpsideDown: .portraitUpsideDown
        ])
    }

    /// Edges are layout-relative: in a right-to-left layout leading is the user's right.
    @Test func rightToLeftFlipsLeadingAndTrailing() {
        let topEdges: [FUInterfaceOrientation: Edge] = [.landscapeRight: .leading, .landscapeLeft: .trailing, .portrait: .top]
        let leftToRight = [FUInterfaceOrientation: FUInterfaceOrientation].contentOrientations(topEdges: topEdges, layoutDirection: .leftToRight)
        let rightToLeft = [FUInterfaceOrientation: FUInterfaceOrientation].contentOrientations(topEdges: topEdges, layoutDirection: .rightToLeft)
        #expect(leftToRight == [.landscapeRight: .portraitUpsideDown, .landscapeLeft: .portraitUpsideDown, .portrait: .portrait])
        #expect(rightToLeft == [.landscapeRight: .portrait, .landscapeLeft: .portrait, .portrait: .portrait])
    }
}
#endif
