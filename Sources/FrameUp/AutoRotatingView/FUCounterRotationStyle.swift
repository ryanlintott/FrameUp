//
//  FUCounterRotationStyle.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-14.
//

#if os(iOS)
import Foundation

/// How the content of an `AutoRotatingView` looks still while the system turns the interface to an orientation the content doesn't allow.
///
/// This only applies when the content keeps its orientation. When the content turns to a different orientation, it turns with the system's timing whichever behavior is set.
public enum FUCounterRotationStyle: Hashable, Sendable {
    /// The content takes its orientation as the system's turn starts, and the system's own transition carries it.
    ///
    /// FrameUp adds no animation, so the content's position can drift and settle as the turn ends, and a half turn can distort it part way through.
    ///
    /// On a device, turning to or from an orientation the content doesn't allow, the content drifts off the centre of the screen part way through the turn and the edges of the turning window crop it, so it looks squeezed towards the middle before it grows back. Use ``hold`` to keep it still.
    case system
    /// The content stays completely still on the screen.
    ///
    /// The content is hosted separately, so preferences set inside it, such as a navigation title or toolbar, don't reach views outside.
    @available(iOS 17, *)
    case hold
}

internal extension FUCounterRotationStyle {
    /// True for ``hold``, comparable on any version.
    var isHeld: Bool {
        guard #available(iOS 17, *) else { return false }
        return self == .hold
    }
}
#endif
