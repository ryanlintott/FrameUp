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
        edge: TabMenuVerticalEdge = .automatic,
        systemEdge: HorizontalEdge? = nil,
        safeAreaInsets: EdgeInsets? = nil,
        verticalSizeClass: UserInterfaceSizeClass? = .compact,
        interfaceOrientation: FUInterfaceOrientation? = .landscapeLeft,
        layoutDirection: LayoutDirection = .leftToRight
    ) -> TabMenuVerticalBar? {
        TabMenuVerticalBar(
            behavior: behavior,
            edge: edge,
            systemEdge: systemEdge,
            safeAreaInsets: safeAreaInsets,
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

    @Test func explicitEdgeMakesACustomBarWhereTheSystemToolbarIsOnTheOtherSide() {
        #expect(verticalBar(edge: .trailing, systemEdge: .leading) == .custom(.trailing))
        #expect(verticalBar(behavior: .system, edge: .leading, systemEdge: .trailing) == .custom(.leading))
    }

    @Test func explicitEdgeUsesTheSystemToolbarOnTheSameSide() {
        #expect(verticalBar(edge: .trailing, systemEdge: .trailing) == .system(.trailing))
    }

    @Test func explicitEdgeMovesTheCustomBar() {
        #expect(verticalBar(edge: .leading, interfaceOrientation: .landscapeLeft) == .custom(.leading))
        #expect(verticalBar(edge: .trailing, interfaceOrientation: .landscapeRight) == .custom(.trailing))
    }

    @Test func explicitEdgeKeepsTheMenuOnTheBottomWhereItIsNotVertical() {
        #expect(verticalBar(behavior: .disabled, edge: .trailing, systemEdge: .leading) == nil)
        #expect(verticalBar(edge: .trailing, verticalSizeClass: .regular) == nil)
    }

    @Test func safeAreaCorrectsTheSystemToolbarEdge() {
        /// The safe area moves to the toolbar's new side an update before `toolbarVerticalEdge` does.
        let leadingColumn = EdgeInsets(top: 0, leading: 84, bottom: 34, trailing: 0)
        #expect(verticalBar(systemEdge: .trailing, safeAreaInsets: leadingColumn) == .system(.leading))
        #expect(verticalBar(edge: .trailing, systemEdge: .trailing, safeAreaInsets: leadingColumn) == .custom(.trailing))
    }

    @Test func evenSafeAreaKeepsTheSystemToolbarEdge() {
        /// As in the iPhone Duo's left split window, which names a toolbar without a safe area for it.
        let noColumn = EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 0)
        #expect(verticalBar(systemEdge: .leading, safeAreaInsets: noColumn) == .system(.leading))
        #expect(verticalBar(systemEdge: nil, safeAreaInsets: EdgeInsets(top: 0, leading: 59, bottom: 21, trailing: 0)) == .custom(.trailing))
    }

    @Test func safeAreaShowsAToolbarBeforeTheEnvironmentDoes() {
        /// Turning into landscape on the iPhone Duo's inner screen, the column's safe area arrives before `toolbarVerticalEdge`.
        let trailingColumn = EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84)
        #expect(verticalBar(systemEdge: nil, safeAreaInsets: trailingColumn, verticalSizeClass: .regular) == .system(.trailing))
    }

    @Test func safeAreaShowsAToolbarHasGoneBeforeTheEnvironmentDoes() {
        /// Turning into portrait on the iPhone Duo's inner screen, the status bar's top safe area arrives before `toolbarVerticalEdge` clears.
        let statusBarOnTop = EdgeInsets(top: 82, leading: 0, bottom: 34, trailing: 0)
        #expect(verticalBar(systemEdge: .trailing, safeAreaInsets: statusBarOnTop, verticalSizeClass: .regular) == nil)
    }

    @Test func otherIPhonesSafeAreasNeverShowAToolbar() {
        /// Even sides, as on an iPhone with a Dynamic Island in landscape.
        #expect(verticalBar(systemEdge: nil, safeAreaInsets: EdgeInsets(top: 0, leading: 62, bottom: 21, trailing: 62), verticalSizeClass: .regular) == nil)
        /// One side only, but not the toolbar's width.
        #expect(verticalBar(systemEdge: nil, safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 21, trailing: 59), verticalSizeClass: .regular) == nil)
        /// The toolbar's width, but with a top safe area.
        #expect(verticalBar(systemEdge: nil, safeAreaInsets: EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 84), verticalSizeClass: .regular) == nil)
    }
}
#endif
