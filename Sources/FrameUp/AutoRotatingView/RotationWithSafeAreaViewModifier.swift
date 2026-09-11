//
//  RotationWithSafeAreaViewModifier.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-10.
//

import SwiftUI

/// Rotates a view, re-creating a container's safe area inside the rotation.
///
/// A `rotationEffect` does not carry a safe area through it, so the container's own safe area has to be built again on the other side. ``insets`` and ``frameSize`` are the values the content rests in at ``angle``, and all three animate together, so a rotation moves each of them directly from the value it rests at at one end to the value it rests at at the other, never passing through anything larger or smaller on the way.
///
/// Content sits centred in the rect the insets leave behind, and moving that rect directly rather than turning it leaves its centre short of where the rotation puts it part way through. ``position`` makes up the difference, so content stays on the axis of rotation without the insets having to bend around it.
internal struct RotationWithSafeAreaViewModifier: ViewModifier, Animatable {
    /// The angle the content is turned to.
    var angle: Angle
    /// The safe area the content rests in at that angle.
    var insets: EdgeInsets
    /// The container as the content sees it at that angle.
    var frameSize: CGSize
    
    /// The size of the container being rotated within.
    private let containerSize: CGSize
    /// The safe area of that container, measured outside the rotation. A content rotation does not move it.
    private let containerSafeAreaInsets: EdgeInsets
    private let layoutDirection: LayoutDirection
    
    /// Rotates a view, re-creating a container's safe area inside the rotation.
    ///
    /// ``insets`` and ``frameSize`` are worked out here rather than as computed properties because they are animated values, and this is the only place the angle is a resting one. Both ``EdgeInsets/rotated(by:layoutDirection:)`` and ``CoreFoundation/CGSize/rotated(by:)`` answer to the nearest quarter turn, so deriving either of them from the angle once it is animating would hold one resting value and then jump to the other halfway through the turn instead of moving directly between them.
    /// - Parameters:
    ///   - angle: Angle to rotate the content to.
    ///   - containerSize: Size of the container being rotated within.
    ///   - safeAreaInsets: Safe area of that container, measured outside the rotation.
    ///   - layoutDirection: Layout direction used to resolve leading and trailing insets into left and right ones.
    init(angle: Angle, containerSize: CGSize, safeAreaInsets: EdgeInsets, layoutDirection: LayoutDirection) {
        self.angle = angle
        self.insets = safeAreaInsets.rotated(by: angle, layoutDirection: layoutDirection)
        self.frameSize = containerSize.rotated(by: angle)
        self.containerSize = containerSize
        self.containerSafeAreaInsets = safeAreaInsets
        self.layoutDirection = layoutDirection
    }
    
    nonisolated var animatableData: AnimatablePair<Angle.AnimatableData, AnimatablePair<EdgeInsets.AnimatableData, CGSize.AnimatableData>> {
        get {
            AnimatablePair(
                angle.animatableData,
                AnimatablePair(insets.animatableData, frameSize.animatableData)
            )
        }
        set {
            angle.animatableData = newValue.first
            insets.animatableData = newValue.second.first
            frameSize.animatableData = newValue.second.second
        }
    }
    
    func body(content: Content) -> some View {
        content
            .safeAreaInsets(insets)
            .rotationEffect(angle)
            .frame(roundedFrameSize)
            .position(position)
    }
    
    /// The frame, with its width and height rounded to whole points.
    ///
    /// A frame whose edges land between points is not treated as touching the edges of its container, and content that ignores the safe area stops expanding into it. That shows up as a flicker through a rotation, where the position lands between points on most frames, and as a permanent gap on any device whose container has an odd width or height, where the resting position lands between points too.
    var roundedFrameSize: CGSize {
        CGSize(width: frameSize.width.rounded(), height: frameSize.height.rounded())
    }
    
    /// Where to put the centre of the frame so the safe area keeps the centre the rotation gives it, rounded so the frame's edges land on whole points.
    ///
    /// The centre of the safe area moves directly along with its insets, so part way through a turn it is not where turning it would have put it. Moving the frame by the difference puts it back. Rounding then moves it by up to half a point, which is far less than the drift it is correcting.
    var position: CGPoint {
        /// Where the centre of the safe area lands once the rotation is applied, and where it needs to land.
        let center = insets.centerOffset(layoutDirection: layoutDirection).rotated(by: angle)
        let target = containerSafeAreaInsets.centerOffset(layoutDirection: layoutDirection)
        let wanted = CGPoint(
            x: containerSize.width / 2 + target.x - center.x,
            y: containerSize.height / 2 + target.y - center.y
        )
        /// Positioning is by centre, so the centre is moved to wherever puts the frame's edges on whole points.
        let size = roundedFrameSize
        return CGPoint(
            x: (wanted.x - size.width / 2).rounded() + size.width / 2,
            y: (wanted.y - size.height / 2).rounded() + size.height / 2
        )
    }
}
