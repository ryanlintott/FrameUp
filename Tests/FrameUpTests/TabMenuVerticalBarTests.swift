//
//  TabMenuVerticalBarTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-09.
//

#if os(iOS)
import SwiftUI
import Testing
@testable import FrameUp

struct TabMenuVerticalBarTests {
    /// Decides the bar for `.automatic` on an iPhone in landscape, with the top of the device on the left, unless told otherwise.
    private func verticalBar(
        behavior: TabMenuVerticalBehavior = .automatic,
        systemEdge: HorizontalEdge? = nil,
        verticalSizeClass: UserInterfaceSizeClass? = .compact,
        interfaceOrientation: FUInterfaceOrientation? = .landscapeLeft,
        layoutDirection: LayoutDirection = .leftToRight
    ) -> TabMenuVerticalBar? {
        TabMenuVerticalBar(
            behavior: behavior,
            systemEdge: systemEdge,
            verticalSizeClass: verticalSizeClass,
            interfaceOrientation: interfaceOrientation,
            layoutDirection: layoutDirection
        )
    }

    @Test func automaticUsesTheCustomBarInCompactHeight() {
        #expect(verticalBar() == .custom(.trailing))
    }

    @Test func systemToolbarVerticalWinsOverTheCustomBar() {
        #expect(verticalBar(systemEdge: .leading) == .system(.leading))
    }

    @Test func systemBehaviorOnlyUsesTheSystemToolbarVertical() {
        #expect(verticalBar(behavior: .system, systemEdge: .trailing) == .system(.trailing))
        #expect(verticalBar(behavior: .system) == nil)
    }

    @Test func disabledBehaviorUsesNeitherBar() {
        #expect(verticalBar(behavior: .disabled, systemEdge: .trailing) == nil)
        #expect(verticalBar(behavior: .disabled) == nil)
    }

    @Test func regularHeightKeepsTheMenuOnTheBottom() {
        #expect(verticalBar(verticalSizeClass: .regular) == nil)
    }

    @Test func customVerticalBarGoesAwayFromTheIsland() {
        /// In `.landscapeLeft` the top of the device is on the left, so the bar is on the right.
        #expect(verticalBar(interfaceOrientation: .landscapeLeft) == .custom(.trailing))
        #expect(verticalBar(interfaceOrientation: .landscapeRight) == .custom(.leading))
    }

    @Test func customVerticalBarKeepsItsPhysicalSideInRightToLeft() {
        #expect(verticalBar(interfaceOrientation: .landscapeLeft, layoutDirection: .rightToLeft) == .custom(.leading))
        #expect(verticalBar(interfaceOrientation: .landscapeRight, layoutDirection: .rightToLeft) == .custom(.trailing))
    }

    @Test func unknownOrientationPutsTheBarOnTheRight() {
        #expect(verticalBar(interfaceOrientation: nil) == .custom(.trailing))
        #expect(verticalBar(interfaceOrientation: .portrait, layoutDirection: .rightToLeft) == .custom(.leading))
    }
}
#endif
