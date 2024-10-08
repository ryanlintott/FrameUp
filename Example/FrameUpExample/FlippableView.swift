//
//  FlippableView.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-07-12.
//

import SwiftUI

struct FlippableView<Front: View, Back: View>: View {
    
    @Binding var angle: Angle
    let axis: Axis = .horizontal
    let anchor: UnitPoint = .center
    let perspective: CGFloat = 1
    let tapToFlip: Bool = true
    let front: () -> Front
    let back: () -> Back
    
    @State private var dragOffset: CGFloat = .zero
    @State private var predictedDragOffset: CGFloat = .zero
    @GestureState private var isDragging: Bool = false
    
    let flipDistance: CGFloat = 200
    var dragAngle: Angle {
        angle + .degrees(CGFloat(180) * min(max(-1, dragOffset / flipDistance), 1))
    }
    var isFaceUp: Bool {
        switch dragAngle.degrees.truncatingRemainder(dividingBy: 360) {
//            case 0..<90, 270..<360: return true
            case 90..<270: return false
            default: return true
        }
//        (Int(flips) % 2) == 0
    }
    
    var rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch axis {
        case .horizontal:
            return (0,1,0)
        case .vertical:
            return (1,0,0)
        }
    }
    
    var body: some View {
        front()
            .rotation3DEffect(dragAngle, axis: rotationAxis, anchor: anchor, perspective: perspective, back: back)
            .gesture(drag)
            .onChange(of: isDragging) { isDragging in
                if !isDragging { onDragEnded() }
            }
            .overlay(
                VStack {
                    Spacer()
                    
                    Text("Face \(isFaceUp ? "Up" : "Down")")
                    Text("Angle: \(angle.degrees)")
                    Text("DragAngle: \(dragAngle.degrees)")
                }
            )
    }
    
    var drag: some Gesture {
        DragGesture()
            .updating($isDragging) { value, gestureState, transaction in
                gestureState = true
            }
            .onChanged { value in
                predictedDragOffset = value.predictedEndTranslation.width
                dragOffset = value.translation.width
            }
//            .exclusively(before: TapGesture().onEnded {
//                rotate(.degrees(180))
//            })
    }
    
    func rotate(_ rotationAngle: Angle, snapTo snapAngle: Angle = .degrees(180)) {
        withAnimation(.spring()) {
            let rotation = Angle.degrees((predictedDragOffset / flipDistance) * rotationAngle.degrees)
            let snapDegrees = snapAngle.degrees
            let remainderAngle = ((angle + rotation).degrees.truncatingRemainder(dividingBy: snapDegrees) + snapDegrees).truncatingRemainder(dividingBy: snapDegrees)
            let snapRotation: Angle
            switch remainderAngle {
            case 0: snapRotation = .zero
            case (snapDegrees/2)..<snapDegrees: snapRotation = .degrees(snapDegrees - remainderAngle)
            case 0..<(snapDegrees/2): snapRotation = .degrees(-remainderAngle)
            default: snapRotation = .zero
            }
            angle += rotation + snapRotation
            dragOffset = .zero
        }
        predictedDragOffset = .zero
    }
    
    func onDragEnded() {
        rotate(.degrees((predictedDragOffset / flipDistance) * 180))
    }
}

struct FlippableView_Previews: PreviewProvider {
    struct PreviewData: View {
        @State private var angle: Angle = .zero
        
        var body: some View {
            FlippableView(angle: $angle) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.blue)
                    .overlay(Text("Up"))
            } back: {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.red)
                    .overlay(Text("Down"))
            }
        }
    }
    
    static var previews: some View {
        PreviewData()
    }
}
