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
    @available(iOS 16, *)
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

    @available(iOS 16, *)
    @Test func automaticUsesTheCustomBarInCompactHeight() {
        #expect(verticalBar() == .custom(.trailing))
    }

    @available(iOS 16, *)
    @Test func systemColumnWinsOverTheCustomBar() {
        #expect(verticalBar(systemEdge: .leading) == .system(.leading))
    }

    @available(iOS 16, *)
    @Test func systemBehaviorOnlyUsesTheSystemColumn() {
        #expect(verticalBar(behavior: .system, systemEdge: .trailing) == .system(.trailing))
        #expect(verticalBar(behavior: .system) == nil)
    }

    @available(iOS 16, *)
    @Test func disabledBehaviorUsesNeitherBar() {
        #expect(verticalBar(behavior: .disabled, systemEdge: .trailing) == nil)
        #expect(verticalBar(behavior: .disabled) == nil)
    }

    @available(iOS 16, *)
    @Test func regularHeightKeepsTheMenuOnTheBottom() {
        #expect(verticalBar(verticalSizeClass: .regular) == nil)
    }

    @available(iOS 16, *)
    @Test func customVerticalBarGoesAwayFromTheIsland() {
        /// In `.landscapeLeft` the top of the device is on the left, so the bar is on the right.
        #expect(verticalBar(interfaceOrientation: .landscapeLeft) == .custom(.trailing))
        #expect(verticalBar(interfaceOrientation: .landscapeRight) == .custom(.leading))
    }

    @available(iOS 16, *)
    @Test func customVerticalBarKeepsItsPhysicalSideInRightToLeft() {
        #expect(verticalBar(interfaceOrientation: .landscapeLeft, layoutDirection: .rightToLeft) == .custom(.leading))
        #expect(verticalBar(interfaceOrientation: .landscapeRight, layoutDirection: .rightToLeft) == .custom(.trailing))
    }

    @available(iOS 16, *)
    @Test func unknownOrientationPutsTheBarOnTheRight() {
        #expect(verticalBar(interfaceOrientation: nil) == .custom(.trailing))
        #expect(verticalBar(interfaceOrientation: .portrait, layoutDirection: .rightToLeft) == .custom(.leading))
    }
}
#endif
