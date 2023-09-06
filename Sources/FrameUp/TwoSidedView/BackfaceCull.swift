//
//  BackfaceCull.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-09-06.
//

import SwiftUI

/// A shape that draws a rectangle matching the frame when the rotation angle is facing forward (angles between -90 and 90 degrees) and nothing when facing backwards (angles between 90 and 270 degrees).
struct BackfaceCull: Shape {
    /// Degrees of rotation. Any additional 360 degree rotaitons will be removed before evaluating.
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
