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
    /// A move between the screens of a foldable iPhone.
    struct ScreenChange: Equatable {
        /// The screen the view has moved to.
        let to: FUDeviceScreen
        /// The device orientation on the screen the view has left, or nil if it isn't known, as on the first report of the screen.
        let from: FUInterfaceOrientation?
    }

    /// The orientation the content turns to, or nil if it stays in the one it's in.
    /// - Parameters:
    ///   - deviceOrientation: The device orientation, or nil if it's unknown, such as lying flat.
    ///   - interfaceOrientation: The interface's current orientation.
    ///   - currentOrientation: The content's current orientation, or nil before it has one.
    ///   - orientationMap: The orientation the content presents in each orientation of the device. A device orientation that isn't in the map leaves the content where it is.
    ///   - preferredOrder: The order to try the presented orientations in when nothing else decides.
    ///   - screenChange: The move between screens, when the view has just moved.
    static func newOrientation(
        deviceOrientation: FUInterfaceOrientation?,
        interfaceOrientation: FUInterfaceOrientation?,
        currentOrientation: FUInterfaceOrientation?,
        orientationMap: [FUInterfaceOrientation: FUInterfaceOrientation],
        preferredOrder: [FUInterfaceOrientation],
        screenChange: ScreenChange?
    ) -> FUInterfaceOrientation? {
        let presentableOrientations = FUInterfaceOrientation.allCases.filter(orientationMap.values.contains)
        let presentedOrientation = deviceOrientation.flatMap { orientationMap[$0] }
        if let screenChange {
            /// There's no place on the new screen to keep, so the content always takes one.
            if let presentedOrientation {
                return presentedOrientation
            }
            /// The interface's entry places the content by the system's UI, such as the vertical bar, which the system set out for the interface orientation it picked. On the outer screen that differs from the device's when the device is in an orientation the system doesn't turn to. On the inner screen the device orientation is already the interface's.
            if let interfaceEntry = interfaceOrientation.flatMap({ orientationMap[$0] }) {
                return interfaceEntry
            }
            if let likelyOrientation = screenChange.from?.likelyOrientations(afterMovingTo: screenChange.to).lazy.compactMap({ orientationMap[$0] }).first {
                return likelyOrientation
            }
            if let nearestOrientation = deviceOrientation?.nearest(in: presentableOrientations) {
                return nearestOrientation
            }
        }
        if let presentedOrientation, presentedOrientation != currentOrientation {
            return presentedOrientation
        }
        if currentOrientation == nil {
            /// The content has to start somewhere: where the interface is, if that's in the map.
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

internal extension FUInterfaceOrientation {
    /// The orientations a foldable iPhone is most likely held in after moving to a screen from this orientation on the other, most likely first.
    ///
    /// Estimates of how the device is held, not measurements.
    /// - Parameter screen: The screen the device has moved to.
    func likelyOrientations(afterMovingTo screen: FUDeviceScreen) -> [Self] {
        switch (screen, self) {
        // Folding, from the inner screen to the outer.
        case (.outer, .portrait), (.outer, .landscapeRight):
            [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]
        case (.outer, .landscapeLeft), (.outer, .portraitUpsideDown):
            [.portrait, .landscapeRight, .landscapeLeft, .portraitUpsideDown]
        // Unfolding, from the outer screen to the inner.
        case (.inner, .portrait):
            [.landscapeRight, .portrait, .portraitUpsideDown, .landscapeLeft]
        case (.inner, .landscapeRight):
            [.portraitUpsideDown, .landscapeRight, .landscapeLeft, .portrait]
        case (.inner, .landscapeLeft):
            [.portrait, .landscapeRight, .landscapeLeft, .portraitUpsideDown]
        case (.inner, .portraitUpsideDown):
            [.landscapeLeft, .portrait, .portraitUpsideDown, .landscapeRight]
        }
    }
}
#endif
