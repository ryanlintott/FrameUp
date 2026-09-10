//
//  Animatable+interpolated.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-10.
//

import SwiftUI

internal extension Animatable {
    /// This value moved directly toward the supplied value by the supplied progress.
    ///
    /// Animatable types already describe themselves as a vector for SwiftUI to interpolate, so this is the same movement an animation would make between the two.
    /// - Parameters:
    ///   - other: Value to move toward.
    ///   - progress: How far to move, from 0 for this value to 1 for the supplied one.
    /// - Returns: A value part way between the two.
    func interpolated(to other: Self, progress: Double) -> Self {
        var data = animatableData
        data.interpolate(towards: other.animatableData, amount: progress)
        var result = self
        result.animatableData = data
        return result
    }
}
