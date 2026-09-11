//
//  RotationWithSafeAreaViewModifierTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-10.
//

import CoreGraphics
import SwiftUI
import Testing
@testable import FrameUp

struct RotationWithSafeAreaViewModifierTests {
    /// An iPhone 17 Pro in portrait.
    static let container = CGSize(width: 402, height: 874)
    static let screenInsets = EdgeInsets(top: 62, leading: 0, bottom: 34, trailing: 0)
    
    /// The rotations an AutoRotatingView can make between two orientations.
    static let turns: [(Angle, Angle)] = [
        (.degrees(0), .degrees(90)),
        (.degrees(0), .degrees(-90)),
        (.degrees(0), .degrees(180)),
        (.degrees(90), .degrees(0)),
        (.degrees(-90), .degrees(180)),
        (.degrees(180), .degrees(270))
    ]
    
    static func geometry(rotatedBy angle: Angle) -> RotationWithSafeAreaViewModifier {
        RotationWithSafeAreaViewModifier(
            angle: angle,
            containerSize: container,
            safeAreaInsets: screenInsets,
            layoutDirection: .leftToRight
        )
    }
    
    /// A rotation sampled from one end to the other, interpolated the way SwiftUI interpolates it.
    static func steps(from previousAngle: Angle, to targetAngle: Angle) -> [RotationWithSafeAreaViewModifier] {
        let start = geometry(rotatedBy: previousAngle)
        let end = geometry(rotatedBy: targetAngle)
        return stride(from: 0.0, through: 1.0, by: 1 / 180).map { start.interpolated(to: end, progress: $0) }
    }
    
    static func expect(_ value: CGFloat, between a: CGFloat, and b: CGFloat, _ label: Comment) {
        #expect(value >= min(a, b) - 1e-9, label)
        #expect(value <= max(a, b) + 1e-9, label)
    }
    
    /// At rest the frame is the container itself, so content that ignores the safe area is edge to edge, and the safe area is the container's own.
    @Test(arguments: [Angle.degrees(0), .degrees(90), .degrees(180), .degrees(270), .degrees(-90), .degrees(360)])
    func atRestTheFrameIsTheContainer(angle: Angle) {
        let geometry = Self.geometry(rotatedBy: angle)
        let isQuarterTurn = Int((angle.degrees / 90).rounded()) % 2 != 0
        let expected = isQuarterTurn ? CGSize(width: Self.container.height, height: Self.container.width) : Self.container
        
        #expect(abs(geometry.roundedFrameSize.width - expected.width) < 1e-9)
        #expect(abs(geometry.roundedFrameSize.height - expected.height) < 1e-9)
        #expect(abs(geometry.position.x - Self.container.width / 2) < 0.5 + 1e-9)
        #expect(abs(geometry.position.y - Self.container.height / 2) < 0.5 + 1e-9)
    }
    
    /// The rule this is all built on. Content sits centred in the safe area, so the centre of the safe area has to stay where the rotation puts it for the whole turn or content drifts off axis part way through.
    ///
    /// The frame is rounded onto whole points so its edges line up with the container's, which moves the centre by up to half a point on each axis. That is the whole tolerance: anything larger is drift.
    static let roundingTolerance: CGFloat = 0.5 * 1.4142135623730951 + 1e-9
    @Test func theSafeAreaCenterStaysOnTheAxisOfRotation() {
        let target = Self.screenInsets.centerOffset(layoutDirection: .leftToRight)
        
        for (from, to) in Self.turns {
            for geometry in Self.steps(from: from, to: to) {
                let center = geometry.insets.centerOffset(layoutDirection: .leftToRight)
                let cosine = CGFloat(cos(geometry.angle.radians))
                let sine = CGFloat(sin(geometry.angle.radians))
                /// Where the centre of the safe area lands on screen, from the centre of the container.
                let onScreen = CGPoint(
                    x: geometry.position.x + center.x * cosine - center.y * sine - Self.container.width / 2,
                    y: geometry.position.y + center.x * sine + center.y * cosine - Self.container.height / 2
                )
                #expect(hypot(onScreen.x - target.x, onScreen.y - target.y) < Self.roundingTolerance, "\(from.degrees) to \(to.degrees) at \(geometry.angle.degrees)")
            }
        }
    }
    
    /// Every inset moves directly from the value it rests at before the rotation to the value it rests at after it, never passing through anything outside that range on the way.
    @Test func everyInsetMovesDirectlyToItsNewValue() {
        let edges: [KeyPath<EdgeInsets, CGFloat>] = [\.top, \.leading, \.bottom, \.trailing]
        
        for (from, to) in Self.turns {
            let start = Self.geometry(rotatedBy: from).insets
            let end = Self.geometry(rotatedBy: to).insets
            
            for geometry in Self.steps(from: from, to: to) {
                for edge in edges {
                    Self.expect(
                        geometry.insets[keyPath: edge],
                        between: start[keyPath: edge],
                        and: end[keyPath: edge],
                        "\(from.degrees) to \(to.degrees) at \(geometry.angle.degrees)"
                    )
                }
            }
        }
    }
    
    /// The frame moves directly to its new size too, so nothing grows and shrinks through the rotation.
    @Test func theFrameMovesDirectlyToItsNewSize() {
        for (from, to) in Self.turns {
            let start = Self.geometry(rotatedBy: from).frameSize
            let end = Self.geometry(rotatedBy: to).frameSize
            
            for geometry in Self.steps(from: from, to: to) {
                let label: Comment = "\(from.degrees) to \(to.degrees) at \(geometry.angle.degrees)"
                Self.expect(geometry.frameSize.width, between: start.width, and: end.width, label)
                Self.expect(geometry.frameSize.height, between: start.height, and: end.height, label)
            }
        }
    }
    
    /// A half turn rests in the same shape it started in, so nothing about the safe area should move at all. Only the content turns.
    @Test func aHalfTurnLeavesTheSafeAreaSizeAlone() {
        for geometry in Self.steps(from: .degrees(0), to: .degrees(180)) {
            #expect(abs(geometry.frameSize.width - Self.container.width) < 1e-9)
            #expect(abs(geometry.frameSize.height - Self.container.height) < 1e-9)
            /// The insets swap top for bottom over the turn, so the two always add up to what they started as.
            #expect(abs(geometry.insets.top + geometry.insets.bottom - 96) < 1e-9)
            #expect(abs(geometry.insets.leading) < 1e-9)
            #expect(abs(geometry.insets.trailing) < 1e-9)
        }
    }
}
