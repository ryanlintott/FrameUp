//
//  ContentOrientationChoiceTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

#if os(iOS)
import SwiftUI
import Testing
@testable import FrameUp

/// How an `AutoRotatingView` chooses its content's orientation.
struct ContentOrientationChoiceTests {
    /// Wordhord's regular iPhone set as presented orientations: fixed to the device in portrait and both landscapes, nothing for upside down.
    static let heldInPortrait: [FUInterfaceOrientation: FUInterfaceOrientation] = [
        .portrait: .portrait,
        .landscapeRight: .portrait,
        .landscapeLeft: .portrait
    ]

    static func choose(
        device: FUInterfaceOrientation?,
        interface: FUInterfaceOrientation? = .portrait,
        current: FUInterfaceOrientation?,
        map: [FUInterfaceOrientation: FUInterfaceOrientation],
        screenChange: ContentOrientationChoice.ScreenChange? = nil
    ) -> FUInterfaceOrientation? {
        ContentOrientationChoice.newOrientation(
            deviceOrientation: device,
            interfaceOrientation: interface,
            currentOrientation: current,
            orientationMap: map,
            preferredOrder: FUInterfaceOrientation.allCases,
            screenChange: screenChange
        )
    }

    @Test func deviceOrientationInTheMapTurnsTheContent() {
        let map: [FUInterfaceOrientation: FUInterfaceOrientation] = [.portrait: .portrait, .landscapeRight: .portraitUpsideDown]
        #expect(Self.choose(device: .landscapeRight, current: .portrait, map: map) == .portraitUpsideDown)
    }

    /// An orientation left out of the map, or an unknown one, leaves the content where it is.
    @Test(arguments: [FUInterfaceOrientation.portraitUpsideDown, nil])
    func missingOrientationStaysPut(device: FUInterfaceOrientation?) {
        #expect(Self.choose(device: device, current: .portrait, map: Self.heldInPortrait) == nil)
    }

    /// At first appearance with no usable device orientation, the content takes the interface's entry.
    @Test func firstAppearanceUsesTheInterfaceEntry() {
        let map: [FUInterfaceOrientation: FUInterfaceOrientation] = [.portrait: .portrait, .landscapeLeft: .portraitUpsideDown]
        #expect(Self.choose(device: nil, interface: .landscapeLeft, current: nil, map: map) == .portraitUpsideDown)
    }

    /// Without an entry for the interface either, it falls back to the first presentable orientation.
    @Test func firstAppearanceFallsBack() {
        let map: [FUInterfaceOrientation: FUInterfaceOrientation] = [.landscapeLeft: .landscapeLeft, .portraitUpsideDown: .portraitUpsideDown]
        #expect(Self.choose(device: nil, interface: .portrait, current: nil, map: map) == .landscapeLeft)
    }

    /// On a new screen the device orientation's entry wins over any guess.
    @Test func screenChangeUsesTheDeviceEntry() {
        let change = ContentOrientationChoice.ScreenChange(to: .outer, from: .landscapeLeft)
        #expect(Self.choose(device: .landscapeRight, current: .portrait, map: Self.heldInPortrait, screenChange: change) == .portrait)
    }

    /// Unfolding a Duo lying flat, held in outer portrait: most likely inner landscape right, so its entry wins.
    @Test func screenChangeUsesTheLikelyOrientation() {
        let map: [FUInterfaceOrientation: FUInterfaceOrientation] = [
            .portrait: .portrait,
            .landscapeRight: .portraitUpsideDown,
            .landscapeLeft: .portrait
        ]
        let change = ContentOrientationChoice.ScreenChange(to: .inner, from: .portrait)
        #expect(Self.choose(device: nil, current: .landscapeLeft, map: map, screenChange: change) == .portraitUpsideDown)
    }

    /// Skips likely orientations that aren't in the map.
    @Test func screenChangeSkipsMissingLikelyOrientations() {
        let map: [FUInterfaceOrientation: FUInterfaceOrientation] = [.landscapeLeft: .landscapeLeft]
        let change = ContentOrientationChoice.ScreenChange(to: .inner, from: .portrait)
        #expect(Self.choose(device: nil, current: .portrait, map: map, screenChange: change) == .landscapeLeft)
    }

    /// The user's estimates of how the Duo is held after folding or unfolding.
    @Test(arguments: [
        (FUDeviceScreen.outer, FUInterfaceOrientation.portrait, [FUInterfaceOrientation.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]),
        (.outer, .landscapeRight, [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]),
        (.outer, .landscapeLeft, [.portrait, .landscapeRight, .landscapeLeft, .portraitUpsideDown]),
        (.outer, .portraitUpsideDown, [.portrait, .landscapeRight, .landscapeLeft, .portraitUpsideDown]),
        (.inner, .portrait, [.landscapeRight, .portrait, .portraitUpsideDown, .landscapeLeft]),
        (.inner, .landscapeRight, [.portraitUpsideDown, .landscapeRight, .landscapeLeft, .portrait]),
        (.inner, .landscapeLeft, [.portrait, .landscapeRight, .landscapeLeft, .portraitUpsideDown]),
        (.inner, .portraitUpsideDown, [.landscapeLeft, .portrait, .portraitUpsideDown, .landscapeRight])
    ])
    func likelyOrientations(screen: FUDeviceScreen, from: FUInterfaceOrientation, expected: [FUInterfaceOrientation]) {
        #expect(from.likelyOrientations(afterMovingTo: screen) == expected)
        #expect(Set(expected) == Set(FUInterfaceOrientation.allCases))
    }
}
#endif
