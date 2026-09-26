//
//  TabMenuLayoutTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI
import Testing
@testable import FrameUp

struct TabMenuLayoutTests {
    @Test func outerPortraitMatchesTheMeasuredSystemBarPosition() {
        let layout = TabMenuLayout(
            edge: .trailing,
            contentSize: CGSize(width: 382, height: 644),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [CGRect(x: 382, y: 0, width: 84, height: 170)],
            itemCount: 4
        )

        #expect(layout == .vertical(
            VerticalTabMenuGeometry(
                width: 72,
                horizontalEdgePadding: 12,
                itemHeight: 50,
                height: 200,
                bottomPadding: 24
            )
        ))
    }

    @Test func bottomCameraSetsTheBottomEdgeAndShrinksEightItems() {
        let layout = TabMenuLayout(
            edge: .trailing,
            contentSize: CGSize(width: 594, height: 432),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [CGRect(x: 594, y: 384, width: 84, height: 82)],
            itemCount: 8
        )

        #expect(layout == .vertical(
            VerticalTabMenuGeometry(
                width: 72,
                horizontalEdgePadding: 12,
                itemHeight: 48,
                height: 384,
                bottomPadding: 82
            )
        ))
    }

    @Test func leadingColumnUsesLayoutRelativeCoordinates() {
        let layout = TabMenuLayout(
            edge: .leading,
            contentSize: CGSize(width: 594, height: 432),
            safeAreaInsets: EdgeInsets(top: 0, leading: 84, bottom: 34, trailing: 0),
            reservedFrames: [CGRect(x: -84, y: 0, width: 84, height: 82)],
            itemCount: 4
        )

        #expect(layout == .vertical(
            VerticalTabMenuGeometry(
                width: 72,
                horizontalEdgePadding: 12,
                itemHeight: 50,
                height: 200,
                bottomPadding: 24
            )
        ))
    }

    @Test func menuFallsBackToHorizontalWhenMinimumTapTargetsDoNotFit() {
        let layout = TabMenuLayout(
            edge: .trailing,
            contentSize: CGSize(width: 594, height: 432),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [CGRect(x: 594, y: 384, width: 84, height: 82)],
            itemCount: 9
        )

        #expect(layout == .horizontal)
    }

    @Test func divisionAcrossTheColumnIsKeptClear() {
        /// A division frame already includes its margins.
        let layout = TabMenuLayout(
            edge: .trailing,
            contentSize: CGSize(width: 300, height: 600),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [CGRect(x: 300, y: 280, width: 84, height: 40)],
            itemCount: 7
        )

        #expect(layout == .horizontal)
    }

    @Test func divisionAcrossTheColumnLeavesTheMenuBelowIt() {
        let layout = TabMenuLayout(
            edge: .trailing,
            contentSize: CGSize(width: 300, height: 600),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [CGRect(x: 300, y: 280, width: 84, height: 40)],
            itemCount: 5
        )

        #expect(layout == .vertical(
            VerticalTabMenuGeometry(
                width: 72,
                horizontalEdgePadding: 12,
                itemHeight: 50,
                height: 250,
                bottomPadding: 24
            )
        ))
    }

    @Test func missingColumnInsetKeepsTheLastMeasuredLayout() {
        let layout = TabMenuLayout(
            edge: .trailing,
            contentSize: CGSize(width: 466, height: 644),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 0),
            reservedFrames: [],
            itemCount: 4
        )

        #expect(layout == .unmeasured)
    }

    @Test func noVerticalEdgeUsesTheHorizontalMenu() {
        let layout = TabMenuLayout(
            edge: nil,
            contentSize: CGSize(width: 393, height: 818),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
            reservedFrames: [],
            itemCount: 4
        )

        #expect(layout == .horizontal)
    }
}
