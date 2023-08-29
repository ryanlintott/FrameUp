//
//  TwoSidedVisionOSView.swift
//
//
//  Created by Ryan Lintott on 2023-08-11.
//

#if os(visionOS)
import SwiftUI

struct TwoSidedVisionOSView<Front: View, Back: View>: View {
    let angle: Angle
    let axis: RotationAxis3D
    let anchor: UnitPoint3D
    let front: () -> Front
    let back: () -> Back
    
    init(angle: Angle, axis: RotationAxis3D, anchor: UnitPoint3D = .center, front: @escaping () -> Front, back: @escaping () -> Back) {
        self.angle = angle
        self.axis = axis
        self.anchor = anchor
        self.front = front
        self.back = back
    }
    
    var backAngle: Angle { angle + .degrees(180) }
    
    var thickness: Double {
        2
    }
    
    var isFaceUp: Bool {
        switch abs(angle.degrees).truncatingRemainder(dividingBy: 360) {
        case 90...270: return false
        default: return true
        }
    }
    
    var body: some View {
        front()
            .accessibilityElement(children: isFaceUp ? .contain : .ignore)
            .accessibilityHidden(isFaceUp)
            .background {
                back()
                    .accessibilityElement(children: isFaceUp ? .ignore : .contain)
                    .accessibilityHidden(!isFaceUp)
                    .offset(z: -thickness / 2)
                    .rotation3DEffect(.degrees(180), axis: axis, anchor: .init(x: anchor.x, y: anchor.y, z: anchor.z - thickness))
            }
            .offset(z: -thickness / 2)
            .rotation3DEffect(angle, axis: axis, anchor: anchor)
    }
}

struct TwoSidedVisionOSView_Previews: PreviewProvider {
    struct PreviewData: View {
        @State private var angle: Angle = .degrees(0)
        @State private var axis: Axis = .horizontal
        
        var body: some View {
            VStack {
                TwoSidedVisionOSView(
                    angle: angle,
                    axis: axis == .horizontal ? .y : .x) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.blue)
                            .overlay(Text("Up"))
                    } back: {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.red)
                            .overlay(Text("Down"))
                    }
                    .padding()
                
                Picker("Axis", selection: $axis) {
                    ForEach(Axis.allCases, id: \.self) { axis in
                        Text("\(axis.description)")
                    }
                }
                .pickerStyle(.segmented)
                
                Text("Change Rotation")
                HStack {
                    ForEach([-360,-180,-120,-45,45,120,180,360], id: \.self) { i in
                        Button("\(i > 0 ? "+" : "")\(i)") {
                            withAnimation(.spring().speed(0.4)) {
                                angle += .degrees(Double(i))
                            }
                        }
                        .padding(1)
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
#endif
