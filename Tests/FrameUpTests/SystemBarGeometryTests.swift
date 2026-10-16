//
//  SystemBarGeometryTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

import SwiftUI
import Testing
@testable import FrameUp

/// The system's bar is measured once and turned with the content of every `AutoRotatingView`.
struct SystemBarGeometryTests {
    static func bar(_ side: SystemBar.Side, start: CGFloat = 10, end: CGFloat = 0) -> SystemBar {
        SystemBar(kind: .verticalToolbar, side: side, depth: 84, clockwiseStart: start, clockwiseEnd: end, reservedDepth: 0)
    }

    /// The bar turns exactly as the safe area does: an inset on the bar's side ends up on the side the turned bar is on.
    @Test(arguments: SystemBar.Side.allCases, [-270.0, -180, -90, 0, 90, 180, 270, 450])
    func turnsLikeTheSafeArea(side: SystemBar.Side, degrees: Double) {
        let inset: CGFloat = 84
        let insets = EdgeInsets(
            top: side == .top ? inset : 0,
            leading: side == .left ? inset : 0,
            bottom: side == .bottom ? inset : 0,
            trailing: side == .right ? inset : 0
        ).rotated(by: .degrees(degrees), layoutDirection: .leftToRight)
        let turned = Self.bar(side).rotated(by: .degrees(degrees), container: .zero).side
        let turnedInsets = [SystemBar.Side.top: insets.top, .right: insets.trailing, .bottom: insets.bottom, .left: insets.leading]
        #expect(turnedInsets[turned] == inset)
    }

    /// A quarter turn clockwise brings a right-hand toolbar to the content's top, and the toolbar's top end, its clockwise start, to the top's left end.
    @Test func quarterTurnKeepsTheEnds() {
        let turned = Self.bar(.right, start: 120, end: 0).rotated(by: .degrees(90), container: .zero)
        #expect(turned.side == .top)
        let geometry = turned.geometry(for: .leftToRight)
        #expect(geometry.edge == .top)
        #expect(geometry.usableStart == 120)
        #expect(geometry.usableEnd == 0)
    }

    /// Edges and ends are named for the layout direction.
    @Test(arguments: [
        (SystemBar.Side.top, LayoutDirection.leftToRight, Edge.top, CGFloat(10), CGFloat(0)),
        (.top, .rightToLeft, .top, 0, 10),
        (.bottom, .leftToRight, .bottom, 0, 10),
        (.bottom, .rightToLeft, .bottom, 10, 0),
        (.right, .leftToRight, .trailing, 10, 0),
        (.right, .rightToLeft, .leading, 10, 0),
        (.left, .leftToRight, .leading, 0, 10),
        (.left, .rightToLeft, .trailing, 0, 10)
    ])
    func layoutRelativeNames(side: SystemBar.Side, layoutDirection: LayoutDirection, edge: Edge, start: CGFloat, end: CGFloat) {
        let geometry = Self.bar(side, start: 10, end: 0).geometry(for: layoutDirection)
        #expect(geometry.edge == edge)
        #expect(geometry.usableStart == start)
        #expect(geometry.usableEnd == end)
    }

    /// Without a vertical toolbar the bar is along the bottom, 50 points above the bottom safe area, between the side safe areas.
    @Test func bottomBar() {
        let bar = SystemBar(toolbarEdge: nil, contentSize: CGSize(width: 402, height: 806), safeAreaInsets: EdgeInsets(top: 62, leading: 4, bottom: 34, trailing: 8), reservedFrames: [], layoutDirection: .leftToRight)
        let geometry = bar?.geometry(for: .leftToRight)
        #expect(geometry?.kind == .bottom)
        #expect(geometry?.edge == .bottom)
        #expect(geometry?.depth == 84)
        #expect(geometry?.usableStart == 4)
        #expect(geometry?.usableEnd == 8)
    }

    /// The iPhone Duo's inner screen in landscape: the column on the right, the camera at its top (measured, iOS 27.1).
    @Test func duoInnerColumn() {
        let bar = SystemBar(toolbarEdge: .trailing, contentSize: CGSize(width: 867, height: 635), safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84), reservedFrames: [CGRect(x: 867, y: 0, width: 84, height: 120)], layoutDirection: .leftToRight)
        #expect(bar?.side == .right)
        let geometry = bar?.geometry(for: .leftToRight)
        #expect(geometry?.kind == .verticalToolbar)
        #expect(geometry?.edge == .trailing)
        #expect(geometry?.depth == 84)
        #expect(geometry?.usableStart == 120)
        #expect(geometry?.usableEnd == 0)
        #expect(geometry?.reservedDepth == 0)
    }

    /// The Duo's left split window names a leading toolbar without a safe area for it, so the app reserves it.
    @Test func duoLeftSplitWindow() {
        let bar = SystemBar(toolbarEdge: .leading, contentSize: CGSize(width: 469, height: 635), safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 0), reservedFrames: [], layoutDirection: .leftToRight)
        #expect(bar?.side == .left)
        #expect(bar?.reservedDepth == 84)
    }

    /// Mid-change, a toolbar named before the safe area reaches it isn't measured, so the last good value is kept.
    @Test func midChangeIsNotMeasured() {
        let bar = SystemBar(toolbarEdge: .trailing, contentSize: CGSize(width: 951, height: 553), safeAreaInsets: EdgeInsets(top: 82, leading: 0, bottom: 34, trailing: 0), reservedFrames: [], layoutDirection: .leftToRight)
        #expect(bar == nil)
    }

    /// The measured toolbar edge in a right-to-left layout is still the physical side it's on.
    @Test func rightToLeftToolbarSide() {
        let bar = SystemBar(toolbarEdge: .leading, contentSize: CGSize(width: 867, height: 635), safeAreaInsets: EdgeInsets(top: 0, leading: 84, bottom: 34, trailing: 0), reservedFrames: [], layoutDirection: .rightToLeft)
        #expect(bar?.side == .right)
        #expect(bar?.geometry(for: .rightToLeft).edge == .leading)
    }
}
