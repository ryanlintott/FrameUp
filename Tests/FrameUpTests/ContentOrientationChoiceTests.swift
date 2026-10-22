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
        map: [FUInterfaceOrientation: FUInterfaceOrientation]
    ) -> FUInterfaceOrientation? {
        ContentOrientationChoice.newOrientation(
            deviceOrientation: device,
            interfaceOrientation: interface,
            currentOrientation: current,
            orientationMap: map,
            preferredOrder: FUInterfaceOrientation.allCases
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

    /// A device orientation without an entry gives way to the interface's, as on a foldable's outer screen held upside down, which the system doesn't turn to.
    @Test func deviceWithoutAnEntryUsesTheInterfaceEntry() {
        let map: [FUInterfaceOrientation: FUInterfaceOrientation] = [.portrait: .landscapeLeft, .landscapeRight: .landscapeLeft, .landscapeLeft: .landscapeRight]
        #expect(Self.choose(device: .portraitUpsideDown, interface: .landscapeLeft, current: nil, map: map) == .landscapeRight)
    }

    /// Without an entry for the interface either, it falls back to the first presentable orientation.
    @Test func firstAppearanceFallsBack() {
        let map: [FUInterfaceOrientation: FUInterfaceOrientation] = [.landscapeLeft: .landscapeLeft, .portraitUpsideDown: .portraitUpsideDown]
        #expect(Self.choose(device: nil, interface: .portrait, current: nil, map: map) == .landscapeLeft)
    }
}
#endif
