//
//  TabMenuVerticalBarLayoutTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-13.
//

import SwiftUI
import Testing
@testable import FrameUp

struct TabMenuVerticalBarLayoutTests {
    @available(iOS 16, *)
    @Test func groupedMenuMatchesTheMeasuredSystemToolbarVerticalPosition() {
        let layout = TabMenuVerticalBarLayout(edge: .trailing, barWidth: 84, topPadding: 170, bottomPadding: 0, isGrouped: true, itemCount: 4, contentInset: 0)

        #expect(layout == TabMenuVerticalBarLayout(
            edge: .trailing,
            menuWidth: 72,
            edgePadding: 12,
            topPadding: 170,
            bottomPadding: 24,
            maxMenuHeight: 200,
            contentInset: 0
        ))
    }

    @available(iOS 16, *)
    @Test func groupedMenuSitsOnTheCameraRatherThanItsMargin() {
        /// Nine items want 450 points, more than the 384 points above the camera, so they squeeze to fit when drawn.
        let layout = TabMenuVerticalBarLayout(edge: .trailing, barWidth: 84, topPadding: 0, bottomPadding: 82, isGrouped: true, itemCount: 9, contentInset: 0)

        #expect(layout.bottomPadding == 82)
        #expect(layout.maxMenuHeight == 450)
    }

    @available(iOS 16, *)
    @Test func equalMenuRunsToTheEdgesOfItsSpan() {
        let layout = TabMenuVerticalBarLayout(edge: .leading, barWidth: 84, topPadding: 82, bottomPadding: 0, isGrouped: false, itemCount: 4, contentInset: 0)

        #expect(layout == TabMenuVerticalBarLayout(
            edge: .leading,
            menuWidth: 72,
            edgePadding: 12,
            topPadding: 82,
            bottomPadding: 0,
            maxMenuHeight: .infinity,
            contentInset: 0
        ))
    }

    @available(iOS 16, *)
    @Test func customBarCentresItsItemsWhereTheSystemDoes() {
        let layout = TabMenuVerticalBarLayout(edge: .trailing, barWidth: TabMenuVerticalBar.customBarWidth, topPadding: 0, bottomPadding: 0, isGrouped: false, itemCount: 4, contentInset: 0)

        /// 48 points from the screen's edge, 6 points further in than the bar's centre.
        #expect(layout.edgePadding + layout.menuWidth / 2 == TabMenuVerticalBarLayout.centreInset)
    }

    @available(iOS 16, *)
    @Test func narrowBarKeepsItsFullWidthForTapTargets() {
        let layout = TabMenuVerticalBarLayout(edge: .trailing, barWidth: 60, topPadding: 0, bottomPadding: 0, isGrouped: false, itemCount: 4, contentInset: 0)

        #expect(layout.menuWidth == 60)
        #expect(layout.edgePadding == 0)
    }
}
