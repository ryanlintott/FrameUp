//
//  RotatedOrientationGeometry.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-10.
//

import SwiftUI

/// The geometry a view needs to rotate between two resting orientations while carrying a container's safe area with it.
///
/// A `rotationEffect` does not carry a safe area through it, so the container's own safe area has to be re-created inside the rotation. Both the size of that safe area and the insets around it move directly from the values they rest at before the rotation to the ones they rest at after it, never passing through anything larger or smaller on the way.
///
/// Content sits centred in the rect those insets leave behind, and moving that rect directly rather than turning it leaves its centre short of where the rotation puts it part way through. The frame is positioned to make up the difference, so the centre stays on the axis of rotation without the insets having to bend around it.
///
/// Everything either end of the rotation rests at is worked out once, when the rotation starts. Only ``progress`` and ``position`` depend on the angle the content is currently turned to.
internal struct RotatedOrientationGeometry {
    /// The angle the content is turned to. This is the only value that changes during a rotation.
    var angle: Angle
    
    private let previousAngle: Angle
    private let targetAngle: Angle
    private let containerSize: CGSize
    private let previousInsets: EdgeInsets
    private let targetInsets: EdgeInsets
    private let previousFrameSize: CGSize
    private let targetFrameSize: CGSize
    /// The centre of the safe area at either end of the rotation, in the local space of the rotated view.
    private let previousCenter: CGPoint
    private let targetCenter: CGPoint
    /// The centre of the safe area in the container, which the rotation does not move.
    private let containerCenter: CGPoint
    
    init(from previousAngle: Angle, to targetAngle: Angle, containerSize: CGSize, safeAreaInsets: EdgeInsets, layoutDirection: LayoutDirection) {
        self.angle = targetAngle
        self.previousAngle = previousAngle
        self.targetAngle = targetAngle
        self.containerSize = containerSize
        self.previousInsets = safeAreaInsets.rotated(by: previousAngle, layoutDirection: layoutDirection)
        self.targetInsets = safeAreaInsets.rotated(by: targetAngle, layoutDirection: layoutDirection)
        self.previousFrameSize = containerSize.rotated(by: previousAngle)
        self.targetFrameSize = containerSize.rotated(by: targetAngle)
        self.previousCenter = previousInsets.centerOffset(layoutDirection: layoutDirection)
        self.targetCenter = targetInsets.centerOffset(layoutDirection: layoutDirection)
        self.containerCenter = safeAreaInsets.centerOffset(layoutDirection: layoutDirection)
    }
    
    /// How far the rotation has come from the angle it started at, from 0 to 1.
    var progress: Double {
        let turn = targetAngle.degrees - previousAngle.degrees
        guard turn != 0 else { return 1 }
        return min(max((angle.degrees - previousAngle.degrees) / turn, 0), 1)
    }
    
    /// The safe area insets the content rests in at either end of the rotation, moved directly from one to the other.
    var insets: EdgeInsets {
        previousInsets.interpolated(to: targetInsets, progress: progress)
    }
    
    /// The container as the content sees it at either end of the rotation, moved directly from one to the other.
    var frameSize: CGSize {
        previousFrameSize.interpolated(to: targetFrameSize, progress: progress)
    }
    
    /// Where to put the centre of the frame so the safe area keeps the centre the rotation gives it.
    ///
    /// The centre of the safe area moves directly along with its insets, so part way through a turn it is not where turning it would have put it. Moving the frame by the difference puts it back.
    var position: CGPoint {
        let center = previousCenter.interpolated(to: targetCenter, progress: progress)
        let cosine = CGFloat(cos(angle.radians))
        let sine = CGFloat(sin(angle.radians))
        /// Where that centre lands on its own once the rotation is applied.
        let rotated = CGPoint(
            x: center.x * cosine - center.y * sine,
            y: center.x * sine + center.y * cosine
        )
        
        return CGPoint(
            x: containerSize.width / 2 + containerCenter.x - rotated.x,
            y: containerSize.height / 2 + containerCenter.y - rotated.y
        )
    }
}

/// Rotates a view between two resting orientations, carrying a container's safe area through the rotation with it.
///
/// The angle is animatable, so the geometry is recalculated frame by frame from the angle the content is actually turned to rather than each value being interpolated on its own.
fileprivate struct RotatedBetweenOrientations: ViewModifier, Animatable {
    var geometry: RotatedOrientationGeometry
    
    nonisolated var animatableData: Double {
        get { geometry.angle.degrees }
        set { geometry.angle = .degrees(newValue) }
    }
    
    func body(content: Content) -> some View {
        content
            .safeAreaInsets(geometry.insets)
            .rotationEffect(geometry.angle)
            .frame(geometry.frameSize)
            .position(geometry.position)
    }
}

internal extension View {
    /// Rotates this view from one resting orientation to another, re-creating the container's safe area inside the rotation.
    ///
    /// The safe area size and insets move directly from where they rest before the rotation to where they rest after it, and the view is positioned so the centre of that safe area stays on the axis of rotation the whole way.
    /// - Parameters:
    ///   - targetAngle: Angle the content is rotating to.
    ///   - previousAngle: Angle the content was resting at before this rotation.
    ///   - containerSize: Size of the container being rotated within.
    ///   - safeAreaInsets: Safe area of that container, measured outside the rotation.
    ///   - layoutDirection: Layout direction used to resolve leading and trailing insets into left and right ones.
    /// - Returns: A rotated view carrying the container's safe area.
    func rotated(to targetAngle: Angle, from previousAngle: Angle, inContainer containerSize: CGSize, safeAreaInsets: EdgeInsets, layoutDirection: LayoutDirection) -> some View {
        modifier(
            RotatedBetweenOrientations(
                geometry: RotatedOrientationGeometry(
                    from: previousAngle,
                    to: targetAngle,
                    containerSize: containerSize,
                    safeAreaInsets: safeAreaInsets,
                    layoutDirection: layoutDirection
                )
            )
        )
    }
}
