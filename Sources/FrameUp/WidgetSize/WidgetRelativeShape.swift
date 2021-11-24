//
//  WidgetRelativeShape.swift
//  
//
//  Created by Ryan Lintott on 2021-11-24.
//

import WidgetKit
import SwiftUI

@available(iOS, unavailable)
@available(iOSApplicationExtension 14.0, *)
/// Used to scale ContainerRelativeShape in order to fix a bug with the corner radius on iPads
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
public typealias WidgetRelativeShape = ScaledShape<ScaledContainerRelativeShape>

@available(iOS, unavailable)
@available(iOSApplicationExtension 14.0, *)
public extension ScaledShape where Content == ScaledContainerRelativeShape {
    /// Creates a scaled `ContainerRelativeShape` in order to fix a bug with the corner radius on iPads.
    /// - Parameter widgetFamily: Pass this in from `@Environment(\.widgetFamily) var widgetFamily`
    init(_ widgetFamily: WidgetFamily) {
        // Scale factor will be less than 1 on iPads and 1 for all other devices
        let scaleFactor = widgetFamily.size?.scaleFactorForCurrentDevice ?? 1
        let scaleSize = CGSize(width: 1 / scaleFactor, height: 1 / scaleFactor)
        self.init(shape: ScaledContainerRelativeShape(scaleFactor: scaleFactor), scale: scaleSize, anchor: .topLeading)
    }
}
