//
//  FUSystemRotationBehavior.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-14.
//

#if os(iOS)
import Foundation

/// How the content of an `AutoRotatingView` moves while the system turns the interface to an orientation the content doesn't allow.
///
/// The system turns the whole window, and the content has to turn back by the same amount to keep its orientation. The two behaviors trade how the content looks during the turn against what it costs.
public enum FUSystemRotationBehavior: Hashable, Sendable {
    /// The content keeps its orientation, but not its place on the screen, through the turn.
    ///
    /// The content changes as the device turns, and the system's rotation animation carries the change with it. Its position drifts off and settles as a quarter turn ends, and a half turn distorts it part way through.
    case lockedOrientation
    /// The content stays completely still on the screen through the turn.
    ///
    /// The content is hosted in a view of its own, which UIKit turns back in step with the system's rotation, and its safe area moves to its new place with the same timing. The content gets the view's environment, but preferences set inside it, such as a navigation title, a toolbar or a hidden status bar, don't reach views outside, and changing `allowedOrientations` between a set that covers every orientation the app supports and one that doesn't rebuilds the content.
    @available(iOS 17, *)
    case locked
}

internal extension FUSystemRotationBehavior {
    /// True for ``locked``, which can only be compared where it's available.
    var isLocked: Bool {
        guard #available(iOS 17, *) else { return false }
        return self == .locked
    }
}
#endif
