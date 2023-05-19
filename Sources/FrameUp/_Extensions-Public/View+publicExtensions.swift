//
//  View+extensions.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-16.
//

import SwiftUI

public extension View {
    /// Positions this view within an invisible frame with the specified size.
    /// - Parameters:
    ///   - size: The fixed size of the resulting view.
    ///   - alignment: The alignment of this view inside the resulting view. alignment applies if this view is smaller than the size given by the resulting frame.
    /// - Returns: A view with fixed size unless a nil size is provided.
    func frame(_ size: CGSize?, alignment: Alignment = .center) -> some View {
        self.frame(width: size?.width, height: size?.height, alignment: alignment)
    }
}
