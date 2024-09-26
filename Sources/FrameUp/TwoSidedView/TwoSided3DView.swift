//
//  TwoSided3DView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-08-11.
//

#if os(visionOS)
import SwiftUI

struct TwoSided3DViewModifier<Back: View>: ViewModifier {
    let angle: Angle
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    let anchor: UnitPoint3D
    let backsideFlip: BacksideFlip
    let thickness: CGFloat
    let back: Back
    
    init(
        angle: Angle,
        axis: (x: CGFloat,
        y: CGFloat,
        z: CGFloat),
        anchor: UnitPoint3D = .center,
        backsideFlip: BacksideFlip = .automatic,
        thickness: CGFloat? = nil,
        back: Back
    ) {
        self.angle = angle
        self.axis = axis
        self.anchor = anchor
        self.backsideFlip = backsideFlip
        self.thickness = thickness ?? 2
        self.back = back
    }
    
    var backsideFlipAxis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        backsideFlip.axis(rotationAxis: axis)
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
                    .frame(depth: thickness, alignment: .back)
                    .perspectiveRotationEffect(.degrees(180), axis: backsideFlipAxis)
            }
            .frame(depth: thickness, alignment: .front)
            .rotation3DEffect(angle, axis: axis, anchor: anchor)
    }
}

extension View {
    /// Rotates this view’s rendered output in three dimensions around the given axis of rotation with a closure containing a different view on the back.
    ///
    /// > Important: If you want a simulated rotation that renders flat, use ``SwiftUICore/View/perspectiveRotationEffect(_:axis:anchor:anchorZ:perspective:backsideFlip:back:)``.
    /// - Parameters:
    ///   - angle: The angle by which to rotate the view’s content.
    ///   - axis: The axis of rotation, specified as a tuple with named elements for each of the three spatial dimensions.
    ///   - anchor: The unit point within the view about which to perform the rotation. The default value is UnitPoint3D/center.
    ///   - backsideFlip: The direction to flip the backside view so that it appear upright when flipped. The default is automatic.
    ///   - thickness: The distance between the front and back views. The default value is 2.
    ///   - back: The view to show on the back.
    /// - Returns: A rotated view with another view on the back.
    public func rotation3DEffect<Back: View>(
        _ angle: Angle,
        axis: (x: CGFloat, y: CGFloat, z: CGFloat),
        anchor: UnitPoint3D = .center,
        backsideFlip: BacksideFlip = .automatic,
        thickness: CGFloat? = nil,
        back: () -> Back
    ) -> some View {
        modifier(TwoSided3DViewModifier(angle: angle, axis: axis, anchor: anchor, thickness: thickness, back: back()))
    }
}
#endif
