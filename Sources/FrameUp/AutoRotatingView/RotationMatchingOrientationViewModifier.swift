//
//  RotationMatchingOrientationViewModifier.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2020-12-31.
//

#if os(iOS)
import SwiftUI

extension View {
    /// Rotates a view and alters it's frame to match device orientations from an allowed orientation set.
    ///
    /// View will use a GeometryReader to take all the available space.
    /// - Parameters:
    ///   - allowedOrientations: Set of allowed orientations for this view. Default is all.
    ///   - isOn: Toggle to turn this modifier on or off.
    ///   - animation: Animation to use when altering the view orientation.
    /// - Returns: A view rotated to match a device orientations from an allowed orientation set.
    @available(*, deprecated, renamed: "AutoRotatingView", message: "Use AutoRotatingView view instead of this modifier.")
    public func rotationMatchingOrientation(_ allowedOrientations: [FUInterfaceOrientation]? = nil, isOn: Bool = true, withAnimation animation: Animation? = nil) -> some View {
        AutoRotatingView(allowedOrientations ?? FUInterfaceOrientation.allCases, isOn: isOn, animation: animation) {
            self
        }
    }
}
#endif
