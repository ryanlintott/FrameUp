//
//  TwoSidedView.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-07-11.
//

import SwiftUI

fileprivate struct BackfaceCull: Shape {
    var degrees: CGFloat
    
    var animatableData: CGFloat {
        get { degrees }
        set { degrees = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch abs(degrees).truncatingRemainder(dividingBy: 360) {
        case 90...270: break
        default: path.addRect(rect)
        }
        return path
    }
}

struct TwoSidedViewModifier<Back: View>: ViewModifier {
    let angle: Angle
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    let anchor: UnitPoint
    let anchorZ: CGFloat
    let perspective: CGFloat
    let back: () -> Back
    
    init(_ angle: Angle, axis: (x: CGFloat, y: CGFloat, z: CGFloat), anchor: UnitPoint, anchorZ: CGFloat, perspective: CGFloat, back: @escaping () -> Back) {
        self.angle = angle
        self.axis = axis
        self.anchor = anchor
        self.anchorZ = anchorZ
        self.perspective = perspective
        self.back = back
    }
    
    var backAngle: Angle { angle + .degrees(180) }
    
    func body(content: Content) -> some View {
        ZStack {
            back()
                .clipShape(BackfaceCull(degrees: backAngle.degrees))
                .clipped()
                .rotation3DEffect(backAngle, axis: axis, anchor: anchor, anchorZ: anchorZ, perspective: perspective)
            
            content
                .clipShape(BackfaceCull(degrees: angle.degrees))
                .clipped()
                .rotation3DEffect(angle, axis: axis, anchor: anchor, anchorZ: anchorZ, perspective: perspective)
        }
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
    public func rotation3DEffect<Back: View>(_ angle: Angle, axis: (x: CGFloat, y: CGFloat, z: CGFloat), anchor: UnitPoint = .center, anchorZ: CGFloat = .zero, perspective: CGFloat = 1, back: @escaping () -> Back) -> some View {
        modifier(TwoSidedViewModifier(angle, axis: axis, anchor: anchor, anchorZ: anchorZ, perspective: perspective, back: back))
    }
}

struct TwoSidedView_Previews: PreviewProvider {
    struct PreviewData: View {
        @State private var angle: Angle = .zero
        
        var body: some View {
            VStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.blue)
                    .overlay(Text("Up"))
                    .rotation3DEffect(angle, axis: (1,1,0), perspective: 0.5) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.red)
                            .overlay(Text("Down"))
                    }
                    .padding()
                
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
