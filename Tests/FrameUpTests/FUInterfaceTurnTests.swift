//
//  FUInterfaceTurnTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

import SwiftUI
import Testing
@testable import FrameUp

/// How a view is turned relative to the interface, and where its edges are.
struct FUInterfaceTurnTests {
    @Test(arguments: [
        (0.0, FUInterfaceTurn.none), (90, .quarterClockwise), (180, .half), (270, .quarterCounterclockwise),
        (-90, .quarterCounterclockwise), (-180, .half), (450, .quarterClockwise), (88, .quarterClockwise)
    ])
    func fromAngle(degrees: Double, expected: FUInterfaceTurn) {
        #expect(FUInterfaceTurn(.degrees(degrees)) == expected)
    }

    /// A quarter turn clockwise puts the view's top at the interface's right, which is trailing left to right and leading right to left.
    @Test func quarterClockwise() {
        let turn = FUInterfaceTurn.quarterClockwise
        #expect(turn.interfaceEdge(of: .top, layoutDirection: .leftToRight) == .trailing)
        #expect(turn.interfaceEdge(of: .top, layoutDirection: .rightToLeft) == .leading)
        #expect(turn.interfaceEdge(of: .leading, layoutDirection: .leftToRight) == .top)
        #expect(turn.localEdge(of: .top, layoutDirection: .leftToRight) == .leading)
        #expect(turn.localEdge(of: .bottom, layoutDirection: .leftToRight) == .trailing)
        #expect(turn.isSideways)
    }

    /// The two conversions undo each other, for every turn, edge and direction.
    @Test(arguments: FUInterfaceTurn.allCases, [LayoutDirection.leftToRight, .rightToLeft])
    func conversionsAreInverse(turn: FUInterfaceTurn, layoutDirection: LayoutDirection) {
        for edge in Edge.allCases {
            #expect(turn.localEdge(of: turn.interfaceEdge(of: edge, layoutDirection: layoutDirection), layoutDirection: layoutDirection) == edge)
        }
    }

    /// The turn agrees with how the safe area is turned: an inset on the interface's edge lands on the view's edge `localEdge(of:)` names.
    @Test(arguments: FUInterfaceTurn.allCases)
    func agreesWithTheSafeArea(turn: FUInterfaceTurn) {
        let insets = EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 0).rotated(by: turn.angle, layoutDirection: .leftToRight)
        let local = turn.localEdge(of: .top, layoutDirection: .leftToRight)
        let value: CGFloat = switch local {
        case .top: insets.top
        case .bottom: insets.bottom
        case .leading: insets.leading
        case .trailing: insets.trailing
        }
        #expect(value == 1)
    }
}

/// Where `systemBarInset` draws the bar, and how far it insets the view's content.
struct SystemBarPlacementTests {
    static let window = CGRect(x: 0, y: 0, width: 402, height: 874)

    /// A view filling the window, with a bar along the bottom: the bar covers the bottom 84 points, and the content moves up by the 50 above the Home indicator.
    @Test func bottomBarFillingView() {
        let bar = SystemBarGeometry(kind: .bottom, edge: .bottom, depth: 84, usableStart: 0, usableEnd: 0, reservedDepth: 0)
        let placement = SystemBarPlacement(bar: bar, container: Self.window, viewFrame: Self.window, safeAreaInsets: EdgeInsets(top: 62, leading: 0, bottom: 34, trailing: 0))
        #expect(placement.barFrame == CGRect(x: 0, y: 790, width: 402, height: 84))
        #expect(placement.insets.bottom == 50)
    }

    /// A vertical toolbar outside the view's safe area draws beside the content without moving it.
    @Test func toolbarOutsideTheSafeArea() {
        let window = CGRect(x: 0, y: 0, width: 951, height: 669)
        let bar = SystemBarGeometry(kind: .verticalToolbar, edge: .trailing, depth: 84, usableStart: 120, usableEnd: 0, reservedDepth: 0)
        let placement = SystemBarPlacement(bar: bar, container: window, viewFrame: window, safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 84))
        #expect(placement.barFrame == CGRect(x: 867, y: 0, width: 84, height: 669))
        #expect(placement.insets == EdgeInsets())
    }

    /// The iPhone Duo's left split window gives the toolbar no safe area, so the content moves over by all of it.
    @Test func reservedToolbar() {
        let window = CGRect(x: 0, y: 0, width: 469, height: 669)
        let bar = SystemBarGeometry(kind: .verticalToolbar, edge: .leading, depth: 84, usableStart: 0, usableEnd: 0, reservedDepth: 84)
        let placement = SystemBarPlacement(bar: bar, container: window, viewFrame: window, safeAreaInsets: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 0))
        #expect(placement.insets.leading == 84)
    }

    /// A view away from the bar's edge gets the bar drawn outside its frame, and no inset.
    @Test func viewAwayFromTheBar() {
        let bar = SystemBarGeometry(kind: .bottom, edge: .bottom, depth: 84, usableStart: 0, usableEnd: 0, reservedDepth: 0)
        let view = CGRect(x: 20, y: 100, width: 300, height: 400)
        let placement = SystemBarPlacement(bar: bar, container: Self.window, viewFrame: view, safeAreaInsets: EdgeInsets())
        #expect(placement.barFrame == CGRect(x: -20, y: 690, width: 402, height: 84))
        #expect(placement.insets == EdgeInsets())
    }
}
