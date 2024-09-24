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

struct TwoSidedRotation3DViewModifier<Back: View>: ViewModifier {
    let rotation: Rotation3D
    let anchor: UnitPoint3D
    let thickness: CGFloat
    let back: Back
    
    init(rotation: Rotation3D, anchor: UnitPoint3D = .center, thickness: CGFloat? = nil, back: Back) {
        self.rotation = rotation
        self.anchor = anchor
        self.thickness = thickness ?? 2
        self.back = back
    }
    
    var isFaceUp: Bool {
        switch abs(rotation.swing(twistAxis: .z).angle.degrees).truncatingRemainder(dividingBy: 360) {
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
                    .perspectiveRotationEffect(.degrees(180), axis: (0, 1, 0))
            }
            .frame(depth: thickness, alignment: .front)
            .rotation3DEffect(rotation, anchor: anchor)
    }
}

extension View {
    /// Rotates this view’s rendered output in three dimensions around the given axis of rotation with a closure containing a different view on the back.
    /// - Parameters:
    ///   - angle: The angle by which to rotate the view’s content.
    ///   - axis: The axis of rotation, specified as a tuple with named elements for each of the three spatial dimensions.
    ///   - anchor: The unit point within the view about which to perform the rotation. The default value is UnitPoint3D/center.
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
        modifier(TwoSidedVisionOSViewModifier(angle: angle, axis: axis, anchor: anchor, thickness: thickness, back: back()))
    }
    
    /// Rotates this view’s rendered output in three dimensions around the given axis of rotation with a closure containing a different view on the back.
    /// - Parameters:
    ///   - rotation: A rotation to apply to the view’s content.
    ///   - anchor: The unit point within the view about which to perform the rotation. The default value is center.
    ///   - thickness: The distance between the front and back views.
    ///   - back: View to show on the back.
    /// - Returns: A rotated view with another view showing on the back.
    public func rotation3DEffect<Back: View>(
        _ rotation: Rotation3D,
        anchor: UnitPoint3D = .center,
        backsideFlip: BacksideFlip = .automatic,
        thickness: CGFloat? = nil,
        back: () -> Back
    ) -> some View {
        modifier(TwoSidedRotation3DViewModifier(rotation: rotation, anchor: anchor, thickness: thickness, back: back()))
    }
}
#endif
