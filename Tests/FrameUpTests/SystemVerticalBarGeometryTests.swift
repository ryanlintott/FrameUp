//
//  SystemVerticalBarGeometryTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI
import Testing
@testable import FrameUp

struct SystemVerticalBarGeometryTests {
    @available(iOS 16, *)
    @Test func outerPortraitMatchesTheMeasuredSystemBarPosition() {
        let geometry = SystemVerticalBarGeometry(
            edge: .trailing,
            contentSize: CGSize(width: 382, height: 644),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [CGRect(x: 382, y: 0, width: 84, height: 170)],
            itemCount: 4
        )

        #expect(geometry == SystemVerticalBarGeometry(
            edge: .trailing,
            width: 72,
            horizontalEdgePadding: 12,
            itemHeight: 50,
            height: 200,
            bottomPadding: 24,
            reservedWidth: 0
        ))
    }

    @available(iOS 16, *)
    @Test func bottomCameraSetsTheBottomEdgeAndShrinksEightItems() {
        let geometry = SystemVerticalBarGeometry(
            edge: .trailing,
            contentSize: CGSize(width: 594, height: 432),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [CGRect(x: 594, y: 384, width: 84, height: 82)],
            itemCount: 8
        )

        #expect(geometry == SystemVerticalBarGeometry(
            edge: .trailing,
            width: 72,
            horizontalEdgePadding: 12,
            itemHeight: 48,
            height: 384,
            bottomPadding: 82,
            reservedWidth: 0
        ))
    }

    @available(iOS 16, *)
    @Test func leadingColumnUsesLayoutRelativeCoordinates() {
        let geometry = SystemVerticalBarGeometry(
            edge: .leading,
            contentSize: CGSize(width: 594, height: 432),
            safeAreaInsets: EdgeInsets(top: 0, leading: 84, bottom: 34, trailing: 0),
            reservedFrames: [CGRect(x: -84, y: 0, width: 84, height: 82)],
            itemCount: 4
        )

        #expect(geometry == SystemVerticalBarGeometry(
            edge: .leading,
            width: 72,
            horizontalEdgePadding: 12,
            itemHeight: 50,
            height: 200,
            bottomPadding: 24,
            reservedWidth: 0
        ))
    }

    @available(iOS 16, *)
    @Test func itemsSqueezeAboveTheCameraWhenMinimumTapTargetsDoNotFit() {
        let geometry = SystemVerticalBarGeometry(
            edge: .trailing,
            contentSize: CGSize(width: 594, height: 432),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [CGRect(x: 594, y: 384, width: 84, height: 82)],
            itemCount: 9
        )

        /// The 384 point span above the camera, shared by nine items.
        #expect(geometry == SystemVerticalBarGeometry(
            edge: .trailing,
            width: 72,
            horizontalEdgePadding: 12,
            itemHeight: 384 / 9,
            height: 384 / 9 * 9,
            bottomPadding: 82,
            reservedWidth: 0
        ))
    }

    @available(iOS 16, *)
    @Test func itemsSqueezeBelowTheHingeRatherThanUsingTheTallerSpanAbove() {
        /// A division frame already includes its margins.
        let geometry = SystemVerticalBarGeometry(
            edge: .trailing,
            contentSize: CGSize(width: 300, height: 600),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [CGRect(x: 300, y: 400, width: 84, height: 40)],
            itemCount: 7
        )

        /// The span above the hinge is 400 points, but the items stay in the 170 point span below it, 440 to 610.
        #expect(geometry == SystemVerticalBarGeometry(
            edge: .trailing,
            width: 72,
            horizontalEdgePadding: 12,
            itemHeight: 170 / 7,
            height: 170 / 7 * 7,
            bottomPadding: 24,
            reservedWidth: 0
        ))
    }

    @available(iOS 16, *)
    @Test func divisionAcrossTheColumnLeavesTheMenuBelowIt() {
        let geometry = SystemVerticalBarGeometry(
            edge: .trailing,
            contentSize: CGSize(width: 300, height: 600),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [CGRect(x: 300, y: 280, width: 84, height: 40)],
            itemCount: 5
        )

        #expect(geometry == SystemVerticalBarGeometry(
            edge: .trailing,
            width: 72,
            horizontalEdgePadding: 12,
            itemHeight: 50,
            height: 250,
            bottomPadding: 24,
            reservedWidth: 0
        ))
    }

    @available(iOS 16, *)
    @Test func columnNamedBeforeItsInsetMovesKeepsTheLastMeasuredLayout() {
        /// Mid-turn, the edge can name the new side while the inset is still on the old one.
        let geometry = SystemVerticalBarGeometry(
            edge: .leading,
            contentSize: CGSize(width: 382, height: 644),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [],
            itemCount: 4
        )

        #expect(geometry == nil)
    }

    @available(iOS 16, *)
    @Test func columnNamedWhileUnfoldingKeepsTheLastMeasuredLayout() {
        /// Mid-unfold, the edge can arrive while the inner portrait's top inset is still there.
        let geometry = SystemVerticalBarGeometry(
            edge: .leading,
            contentSize: CGSize(width: 951, height: 503),
            safeAreaInsets: EdgeInsets(top: 82, leading: 0, bottom: 84, trailing: 0),
            reservedFrames: [],
            itemCount: 4
        )

        #expect(geometry == nil)
    }

    @available(iOS 16, *)
    @Test func leftSplitWindowReservesTheColumn() {
        /// The iPhone Duo's left split window: a leading column with no safe area for it (469x669, bottom inset 34).
        let geometry = SystemVerticalBarGeometry(
            edge: .leading,
            contentSize: CGSize(width: 469, height: 635),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 0),
            reservedFrames: [],
            itemCount: 4
        )

        #expect(geometry == SystemVerticalBarGeometry(
            edge: .leading,
            width: 72,
            horizontalEdgePadding: 12,
            itemHeight: 50,
            height: 200,
            bottomPadding: 24,
            reservedWidth: 84
        ))
    }

    @available(iOS 16, *)
    @Test func noVerticalEdgeHasNoColumn() {
        let geometry = SystemVerticalBarGeometry(
            edge: nil,
            contentSize: CGSize(width: 393, height: 818),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
            reservedFrames: [],
            itemCount: 4
        )

        #expect(geometry == nil)
    }
}
