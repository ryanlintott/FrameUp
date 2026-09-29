//
//  WidgetInterface.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-28.
//

import SwiftUI

/// Which of a device's interfaces a widget is drawn in, where one device presents more than one and the frames differ.
///
/// Almost every device has a single interface and uses ``main``. The exception is a foldable, where unfolding presents a second screen: an iPhone Duo draws a `systemSmall` widget at 158 points on its outer screen and at 190 on its inner screen held in portrait, on the same device with the same widget.
///
/// This is not an orientation. The Duo's inner screen is a quarter turn from the device, so the device held in portrait shows its inner screen in landscape, and that landscape inner screen reports the same frames as the outer screen. Only the inner screen in its own portrait orientation differs, which is why the case names the interface rather than the way the device is being held.
public enum WidgetInterface: String, CaseIterable, Sendable {
    /// The interface a device normally presents, and the only one on every device but a foldable.
    ///
    /// On an iPhone Duo this covers the outer screen, which does not rotate, and the inner screen in landscape.
    case main
    /// A foldable's inner screen, in its own portrait orientation.
    ///
    /// The iPhone Duo is the only device with this interface. Its system widget frames here are 1.2036 times the ones it uses in ``main``, while its Lock Screen accessory frames are unchanged.
    case innerPortrait
}
