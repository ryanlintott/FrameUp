//
//  FlippingView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-12.
//

import SwiftUI

@available(visionOS, deprecated, message: "No replacement at this time")
public struct FlippingView<Front: View, Back: View>: View {
    let axis: Axis
    @Binding var flips: Int
    let flipDistance: CGFloat
    let anchor: UnitPoint
    let anchorZ: CGFloat
    let perspective: CGFloat
    let animation: Animation
    let tapToFlip: Bool
    let dragToFlip: Bool
    let front: () -> Front
    let back: () -> Back
    
    /// A view that has a back side and can be flipped.
    /// - Parameters:
    ///   - axis: Axis of rotation.
    ///   - flips: Number of flips. Even values are face up. Add or remove from this value to flip in either direction.
    ///   - flipDistance: Drag distance required for a complete flip.
    ///   - anchor: The location with a default of center that defines a point in 3D space about which the rotation is anchored.
    ///   - anchorZ: The location with a default of 0 that defines a point in 3D space about which the rotation is anchored.
    ///   - perspective: The relative vanishing point with a default of 1 for this rotation.
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
        self.animation = animation
        self.tapToFlip = tapToFlip
        self.dragToFlip = dragToFlip
        self.front = front
        self.back = back
    }
    
    @State private var dragOffset: CGFloat = .zero
    @State private var predictedDragOffset: CGFloat = .zero
    @GestureState private var isDragging: Bool = false
    
    var isFaceUp: Bool { (flips % 2) == 0 }
    var angle: Angle { .radians(CGFloat(flips) * .pi) }
    var dragAngle: Angle {
        angle + .degrees(CGFloat(180) * min(max(-1, dragOffset / flipDistance), 1))
    }
    
    var rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        axis == .horizontal ? (0,1,0) : (-1,0,0)
    }
    
    public var body: some View {
        VStack {
            front()
                .rotation3DEffect(
                    dragAngle,
                    axis: rotationAxis,
                    anchor: anchor,
                    anchorZ: anchorZ,
                    perspective: perspective,
                    back: back
                )
                .animation(animation, value: flips)
                .animation(animation, value: dragOffset)
                .overlay(
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
                )
                .onChange(of: isDragging) { isDragging in
                    if !isDragging { onDragEnded() }
                }
                .accessibilityAction {
                    flips += 1
                }
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
        DragGesture()
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

@available(visionOS, deprecated, message: "No replacement at this time")
struct FlippingView_Previews: PreviewProvider {
    struct PreviewData: View {
        @State private var flips: Int = 0
        var isFaceUp: Bool { flips.isMultiple(of: 2) }
        @State private var axis: Axis = .horizontal
        @State private var perspective: CGFloat = 1
        
        var body: some View {
            VStack {
                FlippingView(axis, flips: $flips, perspective: perspective) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.blue)
                        .overlay(Text("Up").font(.largeTitle).bold())
                } back: {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.red)
                        .overlay(Text("Down").font(.largeTitle).bold())
                }
                .padding(40)
                
                VStack {
                    HStack {
                        Text("Flips: \(flips)")
                        Spacer()
                        Text("Face \(isFaceUp ? "Up" : "Down")")
                    }
                    
                    HStack {
                        Text("Axis")
                        Picker("Axis", selection: $axis) {
                            ForEach(Axis.allCases, id: \.self) { axis in
                                Text("\(axis.description)")
                            }
                        }
                        #if !os(watchOS)
                        .pickerStyle(.segmented)
                        #endif
                    }
                
                    HStack {
                        Text("Perspective")
                        Slider(value: $perspective, in: 0...1)
                            .padding()
                    }
                    HStack {
                        Text("Programmatic flip")
                        Button("-1") { flips -= 1 }
                        Button("+1") { flips += 1 }
                    }
                }
                .padding()
            }
        }
    }
    
    static var previews: some View {
        PreviewData()
    }
}
