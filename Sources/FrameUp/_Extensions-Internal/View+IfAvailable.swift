//
//  View+IfAvailable.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-07-14.
//

import SwiftUI

extension View {
    /// Applies the given transform.
    ///
    /// Useful for availability branching on view modifiers. Do not branch with any properties that may change during runtime as this will cause errors.
    /// - Parameters:
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: The view transformed by the transform.
    func ifAvailable<Content: View>(@ViewBuilder _ transform: (Self) -> Content) -> some View {
        transform(self)
    }
}
