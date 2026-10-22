//
//  ContentOrientationChoice.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

#if os(iOS)
import SwiftUI

/// How an `AutoRotatingView` chooses its content's orientation.
internal enum ContentOrientationChoice {
    /// The orientation the content turns to, or nil if it stays in the one it's in.
    /// - Parameters:
    ///   - deviceOrientation: The device orientation, or nil if it's unknown, such as lying flat.
    ///   - interfaceOrientation: The interface's current orientation.
    ///   - currentOrientation: The content's current orientation, or nil before it has one, or once it has moved to another screen.
    ///   - orientationMap: The orientation the content presents in each orientation of the device. A device orientation that isn't in the map leaves the content where it is.
    ///   - preferredOrder: The order to try the presented orientations in when nothing else decides.
    static func newOrientation(
        deviceOrientation: FUInterfaceOrientation?,
        interfaceOrientation: FUInterfaceOrientation?,
        currentOrientation: FUInterfaceOrientation?,
        orientationMap: [FUInterfaceOrientation: FUInterfaceOrientation],
        preferredOrder: [FUInterfaceOrientation]
    ) -> FUInterfaceOrientation? {
        let presentableOrientations = FUInterfaceOrientation.allCases.filter(orientationMap.values.contains)
        let presentedOrientation = deviceOrientation.flatMap { orientationMap[$0] }
        if let presentedOrientation, presentedOrientation != currentOrientation {
            return presentedOrientation
        }
        if currentOrientation == nil {
            /// The content has to start somewhere: where the interface is, if that's in the map. On a foldable's outer screen, the interface differs from the device when the device is in an orientation the system doesn't turn to, and its entry places the content by the system's UI, such as the vertical bar.
            return interfaceOrientation.flatMap { orientationMap[$0] }
                ?? preferredOrder.first(where: presentableOrientations.contains)
                ?? presentableOrientations.first
                ?? interfaceOrientation
                ?? .portrait
        }
        /// A device orientation that isn't in the map, or an unknown one, leaves the content where it is.
        return nil
    }
}
#endif
