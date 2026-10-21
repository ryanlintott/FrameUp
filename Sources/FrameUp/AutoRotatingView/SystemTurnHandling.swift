//
//  SystemTurnHandling.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-20.
//

#if os(iOS)
import SwiftUI

/// How an `AutoRotatingView` layer's content handles the system's turn of the interface.
internal enum SystemTurnHandling: Equatable {
    /// The orientations change as soon as the device turns, and the system's rotation carries the change.
    case changesAsDeviceTurns
    /// The orientations change in step with the system's turn.
    case changesWithSystemTurn
    /// The content is hosted so UIKit can hold it still while the system turns the interface.
    case heldStill

    /// - Parameters:
    ///   - counterRotation: The layer's own counter-rotation.
    ///   - enclosingCounterRotation: The counter-rotation an enclosing layer passes on, or nil.
    ///   - hasUnallowedSystemOrientations: True when the system can turn the interface to an orientation the content doesn't allow.
    ///   - deviceScreen: The screen of a foldable iPhone the layer is on.
    init(counterRotation: FUCounterRotationStyle, enclosingCounterRotation: FUCounterRotationStyle?, hasUnallowedSystemOrientations: Bool, deviceScreen: FUDeviceScreen) {
        let style = Self.style(counterRotation, enclosing: enclosingCounterRotation)
        if style.isHeld && hasUnallowedSystemOrientations {
            self = .heldStill
        } else if style == .system && enclosingCounterRotation?.isHeld != true && deviceScreen == .outer {
            self = .changesAsDeviceTurns
        } else {
            self = .changesWithSystemTurn
        }
    }

    /// The counter-rotation a layer passes on to the layers inside it.
    static func passedOnCounterRotation(_ counterRotation: FUCounterRotationStyle, enclosing: FUCounterRotationStyle?, hasUnallowedSystemOrientations: Bool) -> FUCounterRotationStyle? {
        hasUnallowedSystemOrientations ? style(counterRotation, enclosing: enclosing) : enclosing
    }

    /// How the content moves while the system turns the interface. An enclosing `.system` layer sets it for the layers inside, so they stay in step.
    private static func style(_ counterRotation: FUCounterRotationStyle, enclosing: FUCounterRotationStyle?) -> FUCounterRotationStyle {
        if let enclosing, !enclosing.isHeld {
            return enclosing
        }
        return counterRotation
    }
}
#endif
