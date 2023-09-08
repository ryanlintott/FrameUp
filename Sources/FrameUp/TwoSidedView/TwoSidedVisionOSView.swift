//
//  TwoSidedVisionOSView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-08-11.
//

#if os(visionOS)
import SwiftUI

struct TwoSidedVisionOSViewModifier<Back: View>: ViewModifier {
    let angle: Angle
    let axis: RotationAxis3D
    let anchor: UnitPoint3D
    let thickness: CGFloat
    let back: Back
    
    init(angle: Angle, axis: RotationAxis3D, anchor: UnitPoint3D = .center, thickness: CGFloat? = nil, back: Back) {
        self.angle = angle
        self.axis = axis
        self.anchor = anchor
        self.thickness = thickness ?? 2
        self.back = back
    }
    
    var isFaceUp: Bool {
        switch abs(angle.degrees).truncatingRemainder(dividingBy: 360) {
        case 90...270: return false
        default: return true
        }
    }
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: isFaceUp ? .contain : .ignore)
            .accessibilityHidden(isFaceUp)
            .background {
                back
                    .accessibilityElement(children: isFaceUp ? .ignore : .contain)
                    .accessibilityHidden(!isFaceUp)
                    .offset(z: -thickness)
                    .rotation3DEffect(.degrees(180), axis: axis, anchor: .center)
            }
            .offset(z: thickness / 2)
            .rotation3DEffect(angle, axis: axis, anchor: anchor)
    }
}

extension View {
    /// Rotates this view’s rendered output in three dimensions around the given axis of rotation with a closure containing a different view on the back.
    /// - Parameters:
    ///   - angle: The angle at which to rotate the view.
    ///   - axis: The x, y and z elements that specify the axis of rotation.
    ///   - anchor: The location with a default of center that defines a point in 3D space about which the rotation is anchored.
    ///   - anchorZ: The location with a default of 0 that defines a point in 3D space about which the rotation is anchored.
    ///   - perspective: The relative vanishing point with a default of 1 for this rotation.
    ///   - back: View to show on the back.
    /// - Returns: A rotated view with another view showing on the back.
    public func rotation3DEffect<Back: View>(
        _ angle: Angle,
        axis: RotationAxis3D,
        anchor: UnitPoint3D = .center,
        thickness: CGFloat? = nil,
        back: () -> Back
    ) -> some View {
        modifier(TwoSidedVisionOSViewModifier(angle: angle, axis: axis, anchor: anchor, thickness: thickness, back: back()))
    }
}

struct TwoSidedVisionOSView_Previews: PreviewProvider {
    struct PreviewData: View {
        @State private var angle: Angle = .degrees(0)
        @State private var axis: Axis = .horizontal
        
        var body: some View {
            VStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.blue)
                    .overlay(Text("Up"))
                    .rotation3DEffect(
                        angle,
                        axis: axis == .horizontal ? .y : .x,
                        thickness: 2
                    ) {
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
