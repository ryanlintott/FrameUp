//
//  WidgetRelativeShape.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-11-24.
//

import WidgetKit
import SwiftUI

#if os(iOS)
@available(iOS, unavailable)
@available(iOSApplicationExtension 14.0, *)
/// A scalable version of ContainerRelativeShape.
///
/// This shape should not be used directly. Instead, use `WidgetRelativeShape(_ widgetFamily:)`.
public struct ScaledContainerRelativeShape: Shape {
    let scaleFactor: CGFloat
    
    public func path(in rect: CGRect) -> Path {
        let scaledRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.minX + rect.width * scaleFactor,
            height: rect.minY + rect.height * scaleFactor
        )
        // Creating a ContainerRelativeShape in a smaller homeScreen sized frame will adjust the corner radius and fix the problem
        // It will also shrink the overall size but that is adjusted back using WidgetRelativeShape
        return ContainerRelativeShape().path(in: scaledRect)
    }
}

@available(iOS, unavailable)
@available(iOSApplicationExtension 14.0, *)
/// A re-scaled version of `ContainerRelativeShape` used to fix a bug with the corner radius on iPads.
public typealias WidgetRelativeShape = ScaledShape<ScaledContainerRelativeShape>

@available(iOS, unavailable)
@available(iOSApplicationExtension 14.0, *)
public extension ScaledShape where Content == ScaledContainerRelativeShape {
    /// Creates a version of `ContainerRelativeShape` where the corners have been re-scaled in order to fix a bug with the corner radius on iPads.
    ///
    /// This is a bug probably caused by setting the corner radius relative to the Home Screen widget size, then using it on the design canvas size (or vice versa). Hopefully be fixed in a future update but when it is, this shape will no longer have the correct corner radius.
    /// - Parameter widgetFamily: Pass this in from `@Environment(\.widgetFamily) var widgetFamily`
    init(_ widgetFamily: WidgetFamily) {
        // Scale factor will be less than 1 on iPad and 1 for all other devices
        let scaleFactor = widgetFamily.size?.scaleFactorForCurrentDevice ?? 1
        let scaleSize = CGSize(width: 1 / scaleFactor, height: 1 / scaleFactor)
        
        // Creates a ScaledContainerRelativeShape at a smaller size and scales it back up to fit the frame. This re-scales the corner radius.
        self.init(shape: ScaledContainerRelativeShape(scaleFactor: scaleFactor), scale: scaleSize, anchor: .topLeading)
    }
}
#endif
