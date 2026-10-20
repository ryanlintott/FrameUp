//
//  SystemTurnHandlingTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-20.
//

#if os(iOS)
import Testing
@testable import FrameUp

/// How a layer handles the system's turn, and what it passes on to the layers inside, for its own and the enclosing counter-rotation.
struct SystemTurnHandlingTests {
    /// Stands in for ``FUCounterRotationStyle``, whose `hold` case needs iOS 17.
    enum Style: Sendable {
        case system, hold

        var value: FUCounterRotationStyle {
            guard case .hold = self, #available(iOS 17, *) else { return .system }
            return .hold
        }
    }

    struct Row: Sendable, CustomTestStringConvertible {
        let own: Style
        let enclosing: Style?
        let hasUnallowed: Bool
        let screen: FUDeviceScreen
        let handling: SystemTurnHandling
        let passedOn: Style?

        var testDescription: String {
            "\(own) in \(enclosing.map { "\($0)" } ?? "nil"), unallowed \(hasUnallowed), \(screen)"
        }
    }

    static let rows: [Row] = [
        Row(own: .system, enclosing: nil, hasUnallowed: false, screen: .outer, handling: .changesAsDeviceTurns, passedOn: nil),
        Row(own: .system, enclosing: nil, hasUnallowed: true, screen: .outer, handling: .changesAsDeviceTurns, passedOn: .system),
        Row(own: .system, enclosing: nil, hasUnallowed: true, screen: .inner, handling: .changesWithSystemTurn, passedOn: .system),
        Row(own: .hold, enclosing: nil, hasUnallowed: true, screen: .outer, handling: .heldStill, passedOn: .hold),
        Row(own: .hold, enclosing: nil, hasUnallowed: true, screen: .inner, handling: .heldStill, passedOn: .hold),
        Row(own: .hold, enclosing: nil, hasUnallowed: false, screen: .outer, handling: .changesWithSystemTurn, passedOn: nil),
        Row(own: .hold, enclosing: .system, hasUnallowed: true, screen: .outer, handling: .changesAsDeviceTurns, passedOn: .system),
        Row(own: .hold, enclosing: .system, hasUnallowed: false, screen: .inner, handling: .changesWithSystemTurn, passedOn: .system),
        Row(own: .system, enclosing: .hold, hasUnallowed: true, screen: .outer, handling: .changesWithSystemTurn, passedOn: .system),
        Row(own: .system, enclosing: .hold, hasUnallowed: false, screen: .outer, handling: .changesWithSystemTurn, passedOn: .hold),
        Row(own: .hold, enclosing: .hold, hasUnallowed: true, screen: .outer, handling: .heldStill, passedOn: .hold),
        Row(own: .hold, enclosing: .hold, hasUnallowed: false, screen: .outer, handling: .changesWithSystemTurn, passedOn: .hold),
        Row(own: .system, enclosing: .system, hasUnallowed: false, screen: .outer, handling: .changesAsDeviceTurns, passedOn: .system),
        Row(own: .system, enclosing: .system, hasUnallowed: false, screen: .inner, handling: .changesWithSystemTurn, passedOn: .system),
    ]

    @Test(arguments: rows)
    func handling(_ row: Row) {
        let handling = SystemTurnHandling(counterRotation: row.own.value, enclosingCounterRotation: row.enclosing?.value, hasUnallowedSystemOrientations: row.hasUnallowed, deviceScreen: row.screen)
        #expect(handling == row.handling)
        #expect(SystemTurnHandling.passedOnCounterRotation(row.own.value, enclosing: row.enclosing?.value, hasUnallowedSystemOrientations: row.hasUnallowed) == row.passedOn?.value)
    }
}
#endif
