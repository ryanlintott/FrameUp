//
//  FUInterfaceRotationTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

#if os(iOS)
import SwiftUI
import Testing
@testable import FrameUp

/// How a view is rotated relative to the interface, and where its edges are.
struct FUInterfaceRotationTests {
    @Test(arguments: [
        (0.0, FUInterfaceRotation.zero), (90, .degrees90), (180, .degrees180), (270, .degrees270),
        (-90, .degrees270), (-180, .degrees180), (450, .degrees90), (88, .degrees90)
    ])
    func fromAngle(degrees: Double, expected: FUInterfaceRotation) {
        #expect(FUInterfaceRotation(.degrees(degrees)) == expected)
    }

    /// Angles within a degree of a quarter turn map to a rotation, whichever way round they went.
    @Test(arguments: [
        (-270.0, FUInterfaceRotation.degrees90), (-180, .degrees180), (-90, .degrees270), (0, .zero),
        (90, .degrees90), (180, .degrees180), (270, .degrees270), (360, .zero)
    ])
    func exactlyFromQuarterAngle(degrees: Double, expected: FUInterfaceRotation) {
        #expect(FUInterfaceRotation(exactly: .degrees(degrees)) == expected)
    }

    /// Angles between quarter turns have no exact rotation.
    @Test(arguments: [45.0, -45, 135, -135, 88])
    func exactlyFromOtherAngle(degrees: Double) {
        #expect(FUInterfaceRotation(exactly: .degrees(degrees)) == nil)
    }

    /// A quarter turn clockwise puts the view's top at the interface's right, which is trailing left to right and leading right to left.
    @Test func quarterClockwise() {
        let rotation = FUInterfaceRotation.degrees90
        #expect(rotation.interfaceEdge(of: .top, layoutDirection: .leftToRight) == .trailing)
        #expect(rotation.interfaceEdge(of: .top, layoutDirection: .rightToLeft) == .leading)
        #expect(rotation.interfaceEdge(of: .leading, layoutDirection: .leftToRight) == .top)
        #expect(rotation.localEdge(of: .top, layoutDirection: .leftToRight) == .leading)
        #expect(rotation.localEdge(of: .bottom, layoutDirection: .leftToRight) == .trailing)
        #expect(rotation.isSideways)
    }

    /// The two conversions undo each other, for every rotation, edge and direction.
    @Test(arguments: FUInterfaceRotation.allCases, [LayoutDirection.leftToRight, .rightToLeft])
    func conversionsAreInverse(rotation: FUInterfaceRotation, layoutDirection: LayoutDirection) {
        for edge in Edge.allCases {
            #expect(rotation.localEdge(of: rotation.interfaceEdge(of: edge, layoutDirection: layoutDirection), layoutDirection: layoutDirection) == edge)
        }
    }

    /// The rotation agrees with how the safe area is turned: an inset on the interface's edge lands on the view's edge `localEdge(of:)` names.
    @Test(arguments: FUInterfaceRotation.allCases)
    func agreesWithTheSafeArea(rotation: FUInterfaceRotation) {
        let insets = PhysicalEdgeInsets(top: 1).rotated(quarterTurns: rotation.quarterTurns)
        let local = rotation.localEdge(of: .top, layoutDirection: .leftToRight)
        let value: CGFloat = switch local {
        case .top: insets.top
        case .bottom: insets.bottom
        case .leading: insets.left
        case .trailing: insets.right
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
#endif
