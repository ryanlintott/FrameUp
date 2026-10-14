//
//  SystemToolbarVerticalGeometryTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI
import Testing
@testable import FrameUp

struct SystemToolbarVerticalGeometryTests {
    @Test func outerPortraitMatchesTheMeasuredSystemToolbarVerticalPosition() {
        let geometry = SystemToolbarVerticalGeometry(
            edge: .trailing,
            contentSize: CGSize(width: 382, height: 644),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [CGRect(x: 382, y: 0, width: 84, height: 170)]
        )

        #expect(geometry == SystemToolbarVerticalGeometry(
            edge: .trailing,
            width: 84,
            topPadding: 170,
            bottomPadding: 0,
            reservedWidth: 0
        ))
    }

    @Test func bottomCameraSetsTheBottomEdge() {
        let geometry = SystemToolbarVerticalGeometry(
            edge: .trailing,
            contentSize: CGSize(width: 594, height: 432),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [CGRect(x: 594, y: 384, width: 84, height: 82)]
        )

        #expect(geometry == SystemToolbarVerticalGeometry(
            edge: .trailing,
            width: 84,
            topPadding: 0,
            bottomPadding: 82,
            reservedWidth: 0
        ))
    }

    @Test func leadingSystemToolbarVerticalUsesLayoutRelativeCoordinates() {
        let geometry = SystemToolbarVerticalGeometry(
            edge: .leading,
            contentSize: CGSize(width: 594, height: 432),
            safeAreaInsets: EdgeInsets(top: 0, leading: 84, bottom: 34, trailing: 0),
            reservedFrames: [CGRect(x: -84, y: 0, width: 84, height: 82)]
        )

        #expect(geometry == SystemToolbarVerticalGeometry(
            edge: .leading,
            width: 84,
            topPadding: 82,
            bottomPadding: 0,
            reservedWidth: 0
        ))
    }

    @Test func menuSitsBelowTheHingeRatherThanInTheTallerSpanAbove() {
        /// A division frame already includes its margins.
        let geometry = SystemToolbarVerticalGeometry(
            edge: .trailing,
            contentSize: CGSize(width: 300, height: 600),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [CGRect(x: 300, y: 400, width: 84, height: 40)]
        )

        /// The span above the hinge is 400 points, but the menu stays in the span below it, from 440 to the window's bottom edge.
        #expect(geometry == SystemToolbarVerticalGeometry(
            edge: .trailing,
            width: 84,
            topPadding: 440,
            bottomPadding: 0,
            reservedWidth: 0
        ))
    }

    @Test func divisionAcrossTheSystemToolbarVerticalLeavesTheMenuBelowIt() {
        let geometry = SystemToolbarVerticalGeometry(
            edge: .trailing,
            contentSize: CGSize(width: 300, height: 600),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: [CGRect(x: 300, y: 280, width: 84, height: 40)]
        )

        #expect(geometry == SystemToolbarVerticalGeometry(
            edge: .trailing,
            width: 84,
            topPadding: 320,
            bottomPadding: 0,
            reservedWidth: 0
        ))
    }

    @Test func systemToolbarVerticalNamedBeforeItsInsetMovesKeepsTheLastMeasuredLayout() {
        /// Mid-turn, the edge can name the new side while the inset is still on the old one.
        let geometry = SystemToolbarVerticalGeometry(
            edge: .leading,
            contentSize: CGSize(width: 382, height: 644),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84),
            reservedFrames: []
        )

        #expect(geometry == nil)
    }

    @Test func systemToolbarVerticalNamedWhileUnfoldingKeepsTheLastMeasuredLayout() {
        /// Mid-unfold, the edge can arrive while the inner portrait's top inset is still there.
        let geometry = SystemToolbarVerticalGeometry(
            edge: .leading,
            contentSize: CGSize(width: 951, height: 503),
            safeAreaInsets: EdgeInsets(top: 82, leading: 0, bottom: 84, trailing: 0),
            reservedFrames: []
        )

        #expect(geometry == nil)
    }

    @Test func leftSplitWindowReservesTheSystemToolbarVertical() {
        /// The iPhone Duo's left split window: a leading vertical toolbar with no safe area for it (469x669, bottom inset 34).
        let geometry = SystemToolbarVerticalGeometry(
            edge: .leading,
            contentSize: CGSize(width: 469, height: 635),
            safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 0),
            reservedFrames: []
        )

        #expect(geometry == SystemToolbarVerticalGeometry(
            edge: .leading,
            width: 84,
            topPadding: 0,
            bottomPadding: 0,
            reservedWidth: 84
        ))
    }

    @Test func noVerticalEdgeHasNoSystemToolbarVertical() {
        let geometry = SystemToolbarVerticalGeometry(
            edge: nil,
            contentSize: CGSize(width: 393, height: 818),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
            reservedFrames: []
        )

        #expect(geometry == nil)
    }
}
