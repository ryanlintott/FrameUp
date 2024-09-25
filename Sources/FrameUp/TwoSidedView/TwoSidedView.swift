//
//  TwoSidedView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-11.
//

import SwiftUI

public enum BacksideFlip: Equatable, Identifiable {
    /// The backside will be upright when flipped horizontally or vertically and in-between it will choose the option that is the most upright of the two.
    case automatic
    /// The backside will appear upright when flipped horizontally.
    case horizontal
    /// The backside will appear upright when flipped horizontally.
    case vertical
    /// The backside will not be flipped so it will appear mirrored when flipped. This can be useful when flipping non-symmetrical shapes.
    case none
    
    public var id: Self { self }
    
    func axis(rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat)) -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch self {
        case .automatic: abs(rotationAxis.x) >= abs(rotationAxis.y) ? (1, 0, 0) : (0, 1, 0)
        case .horizontal: (0, 1, 0)
        case .vertical: (1, 0, 0)
        case .none: (0, 0, 0)
        }
    }
}

struct TwoSidedViewModifier<Back: View>: ViewModifier {
    let angle: Angle
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    let anchor: UnitPoint
    let anchorZ: CGFloat
    let perspective: CGFloat
    let backsideFlip: BacksideFlip
    let back: Back
    
    init(
        _ angle: Angle,
        axis: (x: CGFloat,
        y: CGFloat,
        z: CGFloat),
        anchor: UnitPoint,
        anchorZ: CGFloat,
        perspective: CGFloat,
        backsideFlip: BacksideFlip = .automatic,
        back: () -> Back
    ) {
        self.angle = angle
        self.axis = axis
        self.anchor = anchor
        self.anchorZ = anchorZ
        self.perspective = perspective
        self.backsideFlip = backsideFlip
        self.back = back()
    }
    
    var backAngle: Angle {
        angle + .degrees(180)
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
    
    var backFlipped: some View {
        back
            .clipShape(BackfaceCull(degrees: backAngle.degrees))
            .accessibilityElement(children: isFaceUp ? .ignore : .contain)
            .accessibilityHidden(!isFaceUp)
            #if os(visionOS)
            .perspectiveRotationEffect(.degrees(180), axis: backsideFlipAxis)
            #else
            .rotation3DEffect(.degrees(180), axis: backsideFlipAxis)
            #endif
    }
    
    func body(content: Content) -> some View {
        content
            .clipShape(BackfaceCull(degrees: angle.degrees))
            .accessibilityElement(children: isFaceUp ? .contain : .ignore)
            .accessibilityHidden(isFaceUp)
            .background(backFlipped)
            #if os(visionOS)
            .perspectiveRotationEffect(angle, axis: axis, anchor: anchor, anchorZ: anchorZ, perspective: perspective)
            #else
            .rotation3DEffect(angle, axis: axis, anchor: anchor, anchorZ: anchorZ, perspective: perspective)
            #endif
    }
}

extension View {
    /// Renders a view’s content as if it’s rotated in three dimensions around the specified axis with a closure containing a different view to show on the back.
    ///
    /// > Important: In visionOS, create this effect with ``SwiftUICore/View/perspectiveRotationEffect(_:axis:anchor:anchorZ:perspective:backsideFlip:back:)`` instead.
    /// To truly rotate a view in three dimensions, use a 3D rotation modifier without a perspective input like ``SwiftUICore/View/rotation3DEffect(_:axis:anchor:backsideFlip:thickness:back:)``.
    /// - Parameters:
    ///   - angle: The angle by which to rotate the view’s content.
    ///   - axis: The axis of rotation, specified as a tuple with named elements for each of the three spatial dimensions.
    ///   - anchor: A two dimensional unit point within the view about which to perform the rotation. The default value is center.
    ///   - anchorZ: The location on the z-axis around which to rotate the content. The default is 0.
    ///   - perspective: The relative vanishing point for the rotation. The default is 1.
    ///   - backsideFlip: The direction to flip the backside view so that it appear upright when flipped. The default is automatic.
    ///   - back: View to show on the back.
    /// - Returns: A rotated view with another view showing on the back.
    @available(visionOS, deprecated, renamed: "rotation3DEffect(_:axis:anchor:backsideFlip:thickness:back:)", message: "Use perpectiveRotationEffect() for a perspective rotation effect or rotation3DEffect() without perspective for a true 3d rotation")
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
    public func rotation3DEffect<Back: View>(
        _ angle: Angle,
        axis: (x: CGFloat, y: CGFloat, z: CGFloat),
        anchor: UnitPoint = .center,
        anchorZ: CGFloat = .zero,
        perspective: CGFloat = 1,
        backsideFlip: BacksideFlip = .automatic,
        back: @escaping () -> Back
    ) -> some View {
        modifier(TwoSidedViewModifier(angle, axis: axis, anchor: anchor, anchorZ: anchorZ, perspective: perspective, backsideFlip: backsideFlip, back: back))
    }
    
    #if os(visionOS)
    /// Renders a view’s content as if it’s rotated in three dimensions around the specified axis with a closure containing a different view to show on the back.
    ///
    /// > Important: To truly rotate a view in three dimensions, use a 3D rotation modifier without a perspective input like ``SwiftUICore/View/rotation3DEffect(_:axis:anchor:backsideFlip:thickness:back:)``.
    /// - Parameters:
    ///   - angle: The angle by which to rotate the view’s content.
    ///   - axis: The axis of rotation, specified as a tuple with named elements for each of the three spatial dimensions.
    ///   - anchor: A two dimensional unit point within the view about which to perform the rotation. The default value is center.
    ///   - anchorZ: The location on the z-axis around which to rotate the content. The default is 0.
    ///   - perspective: The relative vanishing point for the rotation. The default is 1.
    ///   - backsideFlip: The direction to flip the backside view so that it may appear upright when flipped. The default is automatic.
    ///   - back: View to show on the back.
    /// - Returns: A rotated view with another view showing on the back.
    @available(visionOS 1.0, *)
    @available(iOS, unavailable)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    public func perspectiveRotationEffect<Back: View>(
        _ angle: Angle,
        axis: (x: CGFloat, y: CGFloat, z: CGFloat),
        anchor: UnitPoint = .center,
        anchorZ: CGFloat = .zero,
        perspective: CGFloat = 1,
        backsideFlip: BacksideFlip = .automatic,
        back: @escaping () -> Back
    ) -> some View {
        modifier(TwoSidedViewModifier(angle, axis: axis, anchor: anchor, anchorZ: anchorZ, perspective: perspective, backsideFlip: backsideFlip, back: back))
    }
    #endif
}

#Preview {
    RoundedRectangle(cornerRadius: 20)
        .fill(.blue)
        .overlay(Text("Up"))
        #if os(visionOS)
        .perspectiveRotationEffect(.degrees(180), axis: (0.5, 1, 0), perspective: 0.5, backsideFlip: .automatic) {
            RoundedRectangle(cornerRadius: 20)
                .fill(.red)
                .overlay(Text("Down"))
        }
        #else
        .rotation3DEffect(.degrees(180), axis: (0.5, 1, 0), perspective: 0.5, backsideFlip: .automatic) {
            RoundedRectangle(cornerRadius: 20)
                .fill(.red)
                .overlay(Text("Down"))
        }
        #endif
}
