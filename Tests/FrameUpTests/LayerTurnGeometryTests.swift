//
//  LayerTurnGeometryTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-20.
//

#if os(iOS)
import SwiftUI
import Testing
@testable import FrameUp

/// Where a layer's content is, and how it's turned, at a step of a turn.
@MainActor
struct LayerTurnGeometryTests {
    static let portrait = LayerFrame(size: CGSize(width: 402, height: 874), safeAreaInsets: PhysicalEdgeInsets(top: 62, bottom: 34))
    static let landscape = LayerFrame(size: CGSize(width: 874, height: 402), safeAreaInsets: PhysicalEdgeInsets(left: 62, bottom: 21, right: 62))
    static let bar = SystemBar(kind: .verticalToolbar, physicalEdge: .right, depth: 84, clockwiseStart: 10, clockwiseEnd: 0, reservedDepth: 0)

    static func systemTurn(id: Int) -> AutoRotatingTurn {
        AutoRotatingTurn(id: id, kind: .system(angle: .degrees(90), timing: SystemTurnTiming(duration: 0.3)), interfaceOrientation: .landscapeLeft, animation: nil)
    }

    static func geometry(frame: LayerFrame = landscape, interfaceRotation: Angle = .degrees(-90), turnStart: TurnStart? = nil, hold: RotationHold? = nil, turn: AutoRotatingTurn? = systemTurn(id: 1), progress: Double, enclosingSafeAreaTurn: SafeAreaTurn? = nil, systemBar: SystemBar? = bar, enclosingIsTurnStartSystemBar: Bool? = nil) -> LayerTurnGeometry {
        LayerTurnGeometry(frame: frame, interfaceRotation: interfaceRotation, turnStart: turnStart, hold: hold, turn: turn, clockProgress: progress, enclosingContentRotation: ContentRotation(), enclosingSafeAreaTurn: enclosingSafeAreaTurn, systemBar: systemBar, enclosingIsTurnStartSystemBar: enclosingIsTurnStartSystemBar)
    }

    /// Without a turn the content sits at its rotation, in the frame turned to match.
    @Test func atRest() {
        let geometry = Self.geometry(turn: nil, progress: 1)
        #expect(geometry.rotation == .degrees(-90))
        #expect(geometry.contentFrame == Self.landscape.rotated(by: .degrees(-90)))
        #expect(geometry.targetFrame == geometry.contentFrame)
        #expect(geometry.targetInsets == Self.landscape.safeAreaInsets.rotated(quarterTurns: -1))
        #expect(!geometry.isTurnStartSystemBar)
        #expect(geometry.systemBar == Self.bar.rotated(by: .degrees(-90), container: CGRect(origin: .zero, size: geometry.targetFrame.size)))
    }

    /// Content that keeps its orientation through the system's turn turns back by as much as the interface. Not held, it starts in the frame the system has already laid out at its new size.
    @Test func keepsOrientationMidway() {
        let start = TurnStart(id: 1, rotation: .zero, keepsOrientation: true, frame: Self.portrait, systemBar: Self.bar)
        let geometry = Self.geometry(turnStart: start, progress: 0.5)
        #expect(geometry.rotation == .degrees(-45))
        #expect(geometry.contentFrame == Self.landscape.interpolated(to: Self.landscape.rotated(by: .degrees(-90)), progress: 0.5))
        #expect(geometry.targetFrame == Self.landscape.rotated(by: .degrees(-90)))
    }

    /// Content turning to a new orientation takes the short way round.
    @Test func newOrientationTakesShortWay() {
        let start = TurnStart(id: 1, rotation: .degrees(90), keepsOrientation: false, frame: nil, systemBar: nil)
        let geometry = Self.geometry(interfaceRotation: .degrees(-180), turnStart: start, progress: 1)
        #expect(geometry.layerTurn.rotationChange == .degrees(90))
        #expect(abs(geometry.rotation.degrees - 180) < 1e-9)
    }

    /// Before the content takes the turn its host holds, it stays in the host's frame from before the turn and doesn't take the host's turn.
    @Test func heldBeforeTakingTurn() {
        let hold = RotationHold(turnID: 1, timing: SystemTurnTiming(duration: 0.3), angle: .degrees(90), frame: Self.portrait)
        let geometry = Self.geometry(interfaceRotation: .zero, hold: hold, progress: 0.5)
        #expect(geometry.rotation == .zero)
        #expect(geometry.contentFrame == Self.portrait)
        #expect(geometry.targetFrame == Self.portrait)
        #expect(geometry.targetInsets == Self.portrait.safeAreaInsets)
    }

    /// Once the content has taken the turn its host holds, it turns as far again as the host turns the old frame back, starting from the frame before the turn.
    @Test func heldThroughTurn() {
        let hold = RotationHold(turnID: 1, timing: SystemTurnTiming(duration: 0.3), angle: .degrees(90), frame: Self.portrait)
        let start = TurnStart(id: 1, rotation: .zero, keepsOrientation: true, frame: Self.portrait, systemBar: nil)
        let geometry = Self.geometry(turnStart: start, hold: hold, progress: 0.5)
        #expect(geometry.rotation == .degrees(-45) + .degrees(45))
        #expect(geometry.contentFrame == Self.portrait.interpolated(to: Self.landscape.rotated(by: .degrees(-90)), progress: 0.5))
        #expect(geometry.targetFrame == Self.landscape.rotated(by: .degrees(-90)))
    }

    /// Once the host hands over the new frame the turn is done, even if the clock is behind.
    @Test func releasedHoldEndsTurn() {
        let hold = RotationHold(turnID: 1, timing: SystemTurnTiming(duration: 0.3), angle: .degrees(90), frame: Self.portrait, isReleased: true)
        let start = TurnStart(id: 1, rotation: .zero, keepsOrientation: true, frame: nil, systemBar: nil)
        let geometry = Self.geometry(turnStart: start, hold: hold, progress: 0.3)
        #expect(geometry.rotation == .degrees(-90))
        #expect(geometry.contentFrame == Self.landscape.rotated(by: .degrees(-90)))
    }

    /// The outermost layer keeps the bar from before the turn until its new measurement arrives; inner layers follow the enclosing one.
    @Test func turnStartSystemBar() {
        let start = TurnStart(id: 1, rotation: .zero, keepsOrientation: true, frame: nil, systemBar: Self.bar)
        let container = CGRect(origin: .zero, size: Self.landscape.rotated(by: .degrees(-90)).size)
        let kept = Self.geometry(turnStart: start, progress: 0.5)
        #expect(kept.isTurnStartSystemBar)
        #expect(kept.systemBar == Self.bar.rotated(by: .zero, container: container))
        let measured = Self.geometry(turnStart: start, progress: 0.5, systemBar: SystemBar(kind: .verticalToolbar, physicalEdge: .top, depth: 84, clockwiseStart: 10, clockwiseEnd: 0, reservedDepth: 0))
        #expect(!measured.isTurnStartSystemBar)
        #expect(!Self.geometry(turnStart: start, progress: 1).isTurnStartSystemBar)
        #expect(Self.geometry(turnStart: start, progress: 1, enclosingIsTurnStartSystemBar: true).isTurnStartSystemBar)
        #expect(!Self.geometry(turnStart: start, progress: 0.5, enclosingIsTurnStartSystemBar: false).isTurnStartSystemBar)
    }

    /// Turning the bar and then setting its container gives the same bar as doing both at once.
    @Test(arguments: [-180.0, -90, 0, 90, 180, 270])
    func barRotatesOnce(degrees: Double) {
        let container = CGRect(x: 0, y: 0, width: 300, height: 600)
        #expect(Self.bar.rotated(by: .degrees(degrees), container: .zero).rotated(by: .zero, container: container) == Self.bar.rotated(by: .degrees(degrees), container: container))
    }

    /// The target safe area moves on by what the enclosing turn has still to move.
    @Test func enclosingSafeAreaTurn() {
        let safeAreaTurn = SafeAreaTurn(current: PhysicalEdgeInsets(top: 10), target: PhysicalEdgeInsets(top: 30))
        let geometry = Self.geometry(interfaceRotation: .zero, turn: nil, progress: 1, enclosingSafeAreaTurn: safeAreaTurn)
        #expect(geometry.targetInsets == Self.landscape.safeAreaInsets + PhysicalEdgeInsets(top: 20))
    }
}
#endif
