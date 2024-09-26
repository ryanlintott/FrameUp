//
//  PerspectiveFlippingView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2024-09-25.
//

#if os(visionOS)
import SwiftUI

/// A view that simulates a 3d rotation with a back side.
///
/// > Important: To truly rotate a view in three dimensions, use ``FlippingView``.
public struct PerspectiveFlippingView<Front: View, Back: View>: View {
    let axis: Axis
    @Binding var flips: Int
    let flipDistance: CGFloat
    let anchor: UnitPoint
    let anchorZ: CGFloat
    let perspective: CGFloat
    let backsideFlip: BacksideFlip
    let animation: Animation
    let tapToFlip: Bool
    let dragToFlip: Bool
    let front: () -> Front
    let back: () -> Back
    
    /// A view that simulates a rotation in three dimensions with a perspective effect. The rotation occurs around a specified axis via drag gestures and taps. A closure contains another view that is shown on the back.
    ///
    /// > Important: To truly rotate a view in three dimensions, use ``FlippingView``.
    /// - Parameters:
    ///   - axis: Axis of rotation.
    ///   - flips: Number of flips. Even values are face up. Add or remove from this value to flip in either direction.
    ///   - flipDistance: Drag distance required for a complete flip.
    ///   - anchor: The location with a default of center that defines a point in 3D space about which the rotation is anchored.
    ///   - anchorZ: The location with a default of 0 that defines a point in 3D space about which the rotation is anchored.
    ///   - perspective: The relative vanishing point with a default of 1 for this rotation.
    ///   - backsideFlip: The direction to flip the backside view so that it appear upright when flipped. The default is automatic.
    ///   - animation: Animation to use to complete the flip. Default is .spring()
    ///   - tapToFlip: Tap to flip enabled if true. Default is true.
    ///   - dragToFlip: Drag to flip enabled if true. Default is true.
    ///   - front: Front view.
    ///   - back: Back view
    public init(
        _ axis: Axis = .horizontal,
        flips: Binding<Int>,
        flipDistance: CGFloat = 200,
        anchor: UnitPoint = .center,
        anchorZ: CGFloat = .zero,
        perspective: CGFloat = 1,
        backsideFlip: BacksideFlip = .automatic,
        animation: Animation = .spring(),
        tapToFlip: Bool = true,
        dragToFlip: Bool = true,
        front: @escaping () -> Front,
        back: @escaping () -> Back
    ) {
        self.axis = axis
        self._flips = flips
        self.flipDistance = flipDistance
        self.anchor = anchor
        self.anchorZ = anchorZ
        self.perspective = perspective
        self.backsideFlip = backsideFlip
        self.animation = animation
        self.tapToFlip = tapToFlip
        self.dragToFlip = dragToFlip
        self.front = front
        self.back = back
    }
    
    var isFaceUp: Bool { (flips % 2) == 0 }
    var angle: Angle { .radians(CGFloat(flips) * .pi) }
    var rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        axis == .horizontal ? (0,1,0) : (-1,0,0)
    }
    
    @State private var dragOffset: CGFloat = .zero
    @State private var predictedDragOffset: CGFloat = .zero
    @GestureState private var isDragging: Bool = false
    
    var dragAngle: Angle {
        angle + .degrees(CGFloat(180) * min(max(-1, dragOffset / flipDistance), 1))
    }
    
    public var body: some View {
        VStack {
            front()
                .perspectiveRotationEffect(
                    dragAngle,
                    axis: rotationAxis,
                    anchor: anchor,
                    anchorZ: anchorZ,
                    perspective: perspective,
                    backsideFlip: backsideFlip,
                    back: back
                )
                .animation(animation, value: flips)
                .animation(animation, value: dragOffset)
                .overlay(gestureOverlay)
        }
    }
    
    var gestureOverlay: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
            
            if tapToFlip {
                switch axis {
                case .horizontal:
                    HStack(spacing: 0) {
                        tapToFlipTargets
                    }
                case .vertical:
                    VStack(spacing: 0) {
                        tapToFlipTargets
                    }
                }
            }
        }
        .gesture(dragToFlip ? drag : nil)
        .onChange(of: isDragging) { _, newValue in
            if !newValue { onDragEnded() }
        }
        .accessibilityAction {
            flips += 1
        }
    }
    
    var tapToFlipTargets: some View {
        Group {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    flips -= 1
                }
            
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    flips += 1
                }
        }
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isDragging) { value, gestureState, transaction in
                gestureState = true
            }
            .onChanged { value in
                switch axis {
                case .horizontal:
                    predictedDragOffset = value.predictedEndTranslation.width
                    dragOffset = value.translation.width
                case .vertical:
                    predictedDragOffset = value.predictedEndTranslation.height
                    dragOffset = value.translation.height
                }
            }
    }
    
    func onDragEnded() {
        flips += min(max(-1, Int((predictedDragOffset / flipDistance).rounded())), 1)
        dragOffset = .zero
    }
}
#endif
