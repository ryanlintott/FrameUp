//
//  LayerTurnGeometry.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-20.
//

#if os(iOS)
import SwiftUI

/// Where a layer's content was when it took a turn.
internal struct TurnStart: Equatable {
    let id: Int
    /// The content's rotation relative to the interface.
    let rotation: Angle
    /// True when the content turns back by exactly as much as the interface turns.
    let keepsOrientation: Bool
    /// The outermost layer's frame before the system's turn, or nil.
    let frame: LayerFrame?
    let systemBar: SystemBar?
}

/// How an `AutoRotatingView` layer's content is turned and sized in its frame at one step of the latest turn.
internal struct LayerTurnGeometry: Equatable {
    /// How the content turns relative to the frame.
    let layerTurn: LayerTurn
    /// The content's rotation relative to the frame at this step.
    let rotation: Angle
    /// The content's frame at this step.
    let contentFrame: LayerFrame
    /// The content's frame once the turn is over.
    let targetFrame: LayerFrame
    /// The content's safe area once the turn is over, moved on by what the enclosing turn has still to move.
    let targetInsets: PhysicalEdgeInsets
    /// True until the bar's new measurement arrives or the turn ends.
    let isTurnStartSystemBar: Bool
    /// The system's bar as seen from the content.
    let systemBar: SystemBar?

    /// - Parameters:
    ///   - frame: The layer's frame.
    ///   - interfaceRotation: The content's rotation relative to the interface.
    ///   - turnStart: Where the content was when it took the latest turn, or nil if it didn't take it or has changed since.
    ///   - hold: How a host holds the content still through the system's turn, or nil when it isn't hosted.
    ///   - turn: The latest turn.
    ///   - clockProgress: How far through the latest turn the clock is.
    ///   - enclosingContentRotation: The enclosing content's rotation relative to the interface.
    ///   - enclosingSafeAreaTurn: The enclosing content's safe area now and once its turn is over.
    ///   - systemBar: The system's bar in the layer's frame.
    ///   - enclosingIsTurnStartSystemBar: Whether the enclosing layer still shows the bar from the start of the turn, or nil for the outermost layer. Inner layers follow it, so all switch together.
    init(frame: LayerFrame, interfaceRotation: Angle, turnStart: TurnStart?, hold: RotationHold?, turn: AutoRotatingTurn?, clockProgress: Double, enclosingContentRotation: ContentRotation, enclosingSafeAreaTurn: SafeAreaTurn?, systemBar: SystemBar?, enclosingIsTurnStartSystemBar: Bool?) {
        /// The hold while the host keeps the frame from before the turn.
        let holding = hold.flatMap { $0.isReleased ? nil : $0 }
        let isHoldTurn = hold?.isFor(turn) ?? false
        /// True once the content has taken the turn its host holds it through.
        let isHeldThroughTurn = holding != nil && isHoldTurn && turnStart != nil
        /// Until the content takes the turn its host holds, it stays in the frame from before it.
        let isHeldBack = holding != nil && !isHeldThroughTurn
        /// Done once the host has handed over the new frame, even if the clock is a frame behind.
        let progress = isHoldTurn && hold?.isReleased == true ? 1 : clockProgress
        /// Content that keeps its orientation turns exactly as far as the interface; content that turns to a new one takes the short way.
        let layerTurn = LayerTurn(enclosing: enclosingContentRotation, start: turnStart?.rotation ?? interfaceRotation, target: interfaceRotation, isShortWay: turnStart.map { !$0.keepsOrientation } ?? false)
        let layoutFrame = holding?.frame ?? frame
        let targetFrame = (isHeldBack ? layoutFrame : frame).rotated(by: layerTurn.targetRotation)
        let frameTargetInsets = if isHeldBack {
            layoutFrame.safeAreaInsets
        } else {
            frame.safeAreaInsets + (enclosingSafeAreaTurn.map { $0.target - $0.current } ?? PhysicalEdgeInsets())
        }
        let isTurnStartSystemBar = enclosingIsTurnStartSystemBar ?? turnStart.map { progress < 1 && $0.systemBar == systemBar } ?? false

        self.layerTurn = layerTurn
        /// The host turns the old frame back by the system's turn, so the content inside turns as far again.
        rotation = layerTurn.rotation(progress: progress) + (isHeldThroughTurn ? .degrees(holding!.angle.degrees * progress) : .zero)
        /// Only held content starts from the frame before the system's turn. Otherwise the system has already laid the frame out at its new size and turns it.
        contentFrame = (isHeldThroughTurn ? turnStart?.frame ?? layoutFrame : layoutFrame).rotated(by: layerTurn.startRotation).interpolated(to: targetFrame, progress: progress)
        self.targetFrame = targetFrame
        targetInsets = frameTargetInsets.rotated(quarterTurns: layerTurn.targetRotation.quarterTurns)
        self.isTurnStartSystemBar = isTurnStartSystemBar
        self.systemBar = systemBar?.rotated(by: isTurnStartSystemBar ? layerTurn.startRotation : layerTurn.targetRotation, container: CGRect(origin: .zero, size: targetFrame.size))
    }
}
#endif
