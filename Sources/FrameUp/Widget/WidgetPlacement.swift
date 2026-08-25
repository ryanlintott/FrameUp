//
//  WidgetPlacement.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-08-25.
//

import SwiftUI

/// A place a widget can appear, mirroring `WidgetKit.WidgetLocation` so it can be used without importing WidgetKit and on platforms where that type is unavailable.
///
/// A widget size can have a different frame in different places on the same device. An iPad `systemSmall` is 155x155 on the Home Screen and 152x152 on the Lock Screen.
///
/// > Note: This is a different distinction from ``WidgetTarget``. That separates an iPad's design canvas from the smaller Home Screen frame the canvas is scaled into, which is a scaling relationship between two frames for the same placement.
public enum WidgetPlacement: String, CaseIterable, Sendable {
    case homeScreen
    case lockScreen
    case standBy
    case carPlay
    case watchFace
    case smartStack
    case iPhoneWidgetsOnMac
}

public extension WidgetPlacement {
    /// Order used when a lookup does not name a placement.
    ///
    /// Frames are merged in this order with the Home Screen applied last, so a widget size that has a Home Screen frame reports that one, and a size that only appears elsewhere, such as an accessory widget on the Lock Screen, reports the frame from where it does appear.
    static let defaultResolutionOrder: [WidgetPlacement] = [
        .iPhoneWidgetsOnMac,
        .watchFace,
        .smartStack,
        .carPlay,
        .standBy,
        .lockScreen,
        .homeScreen
    ]
}
