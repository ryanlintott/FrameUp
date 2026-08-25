//
//  WidgetFrameSet+all.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-08-25.
//

import SwiftUI

extension WidgetFrameSet {
    /// Every known set of widget frames.
    ///
    /// iPhone sets from iOS 26 onward were measured with the `WidgetSizeProbe` widget in the example app. Everything else is sourced from [Apple Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications), which describes iOS 18 and earlier. Spot checks on iOS 18.6 confirmed the published iPhone values, including the 402 and 440 point wide screens that Apple never published a row for.
    static let all: [WidgetFrameSet] = iPhoneiOS15 + iPhoneiOS26

    /// iPhone frames for iOS 18 and earlier, as published by Apple.
    ///
    /// These are published values rather than measurements. Three of them were confirmed on iOS 18.6 with the `WidgetSizeProbe` widget and are marked below, including 440x956 and 402x874 which Apple never published a row for. The rest are unverified.
    ///
    /// > Note: `extraLargePortrait` is supported on iPhone from iOS 27 but has no frame here yet, so it is omitted.
    private static let iPhoneiOS15: [WidgetFrameSet] = [
        // Confirmed on iPhone 16 Pro Max (iPhone17,2), iOS 18.6, which reports a 440x956 screen and resolves here by nearest width
        iPhoneiOS15(screenSize: (430, 932), small: (170, 170), medium: (364, 170), large: (364, 382), circular: (76, 76), rectangular: (172, 76), inline: (257, 26)),
        iPhoneiOS15(screenSize: (428, 926), small: (170, 170), medium: (364, 170), large: (364, 382), circular: (76, 76), rectangular: (172, 76), inline: (257, 26)),
        iPhoneiOS15(screenSize: (414, 896), small: (169, 169), medium: (360, 169), large: (360, 379), circular: (76, 76), rectangular: (160, 72), inline: (248, 26)),
        iPhoneiOS15(screenSize: (414, 736), small: (159, 159), medium: (348, 157), large: (348, 357), circular: (76, 76), rectangular: (170, 76), inline: (248, 26)),
        // Confirmed on iPhone 16 Pro (iPhone17,1), iOS 18.6, which reports a 402x874 screen and resolves here by nearest width
        iPhoneiOS15(screenSize: (393, 852), small: (158, 158), medium: (338, 158), large: (338, 354), circular: (72, 72), rectangular: (160, 72), inline: (234, 26)),
        // Confirmed on iPhone 13 (iPhone14,5), iOS 18.6
        iPhoneiOS15(screenSize: (390, 844), small: (158, 158), medium: (338, 158), large: (338, 354), circular: (72, 72), rectangular: (160, 72), inline: (234, 26)),
        iPhoneiOS15(screenSize: (375, 812), small: (155, 155), medium: (329, 155), large: (329, 345), circular: (72, 72), rectangular: (157, 72), inline: (225, 26)),
        iPhoneiOS15(screenSize: (375, 667), small: (148, 148), medium: (321, 148), large: (321, 324), circular: (68, 68), rectangular: (153, 68), inline: (225, 26)),
        // No device has been observed reporting this screen size. It is likely a Display Zoom mode rather than a device's native size.
        iPhoneiOS15(screenSize: (360, 780), small: (155, 155), medium: (329, 155), large: (329, 345), circular: (72, 72), rectangular: (157, 72), inline: (225, 26)),
        iPhoneiOS15(screenSize: (320, 568), small: (141, 141), medium: (292, 141), large: (292, 311), circular: (72, 72), rectangular: (157, 72), inline: (225, 26))
    ]

    /// iPhone frames for iOS 26 and later, measured rather than published.
    ///
    /// Values are written in pixels because every measured frame lands on a whole number of pixels. Dividing by the display scale reproduces the fractional point values exactly. The frames themselves are stored in points.
    ///
    /// > Note: the accessory sizes and `extraLargePortrait` have not been measured on iOS 26 yet, so they are omitted here. Sets layer rather than replace, so a lookup on iOS 26 still returns the published accessory frames from the iOS 15 set. Those values are unverified on iOS 26 and may have changed the way the system sizes did.
    private static let iPhoneiOS26: [WidgetFrameSet] = [
        // Measured on iPhone 17 Pro Max (iPhone18,2), iOS 27.0
        iPhoneiOS26(screenSize: (440, 956), displayScale: 3, small: (530, 530), medium: (1134, 530), large: (1134, 1182)),
        // Measured on iPhone 16 Plus (iPhone17,4), iOS 26.5
        iPhoneiOS26(screenSize: (430, 932), displayScale: 3, small: (524, 524), medium: (1116, 524), large: (1116, 1164)),
        // Measured on iPhone 13 Pro Max (iPhone14,3), iOS 26.5
        iPhoneiOS26(screenSize: (428, 926), displayScale: 3, small: (523, 523), medium: (1115, 523), large: (1115, 1161)),
        // Measured on iPhone Air (iPhone18,4), iOS 27.0
        iPhoneiOS26(screenSize: (420, 912), displayScale: 3, small: (518, 518), medium: (1100, 518), large: (1100, 1146)),
        // Measured on iPhone 11 (iPhone12,1), iOS 26.5. Also the iPhone XR.
        iPhoneiOS26(screenSize: (414, 896), displayScale: 2, small: (333, 333), medium: (712, 333), large: (712, 743)),
        // Measured on iPhone 11 Pro Max (iPhone12,5), iOS 26.5. Also the iPhone XS Max. Same screen size in points as the iPhone 11 above but at 3x, and the frames differ by 4.83 points, which is why display scale is part of the key.
        iPhoneiOS26(screenSize: (414, 896), displayScale: 3, small: (514, 514), medium: (1088, 514), large: (1088, 1134)),
        // Measured on iPhone 17 (iPhone18,3) and iPhone 17 Pro (iPhone18,1), iOS 26.5 and 27.0
        iPhoneiOS26(screenSize: (402, 874), displayScale: 3, small: (493, 493), medium: (1049, 493), large: (1049, 1095)),
        // Measured on iPhone 16 (iPhone17,3), iOS 26.5
        iPhoneiOS26(screenSize: (393, 852), displayScale: 3, small: (488, 488), medium: (1034, 488), large: (1034, 1080)),
        // Measured on iPhone 13 (iPhone14,5) and iPhone 17e (iPhone18,5), iOS 26.5 and 27.0
        iPhoneiOS26(screenSize: (390, 844), displayScale: 3, small: (486, 486), medium: (1026, 486), large: (1026, 1074)),
        // Measured on iPhone 11 Pro (iPhone12,3) and iPhone 13 mini (iPhone14,4), iOS 26.5
        iPhoneiOS26(screenSize: (375, 812), displayScale: 3, small: (477, 477), medium: (1001, 477), large: (1001, 1047)),
        // Measured on iPhone SE 3rd generation (iPhone14,6), iOS 26.5
        iPhoneiOS26(screenSize: (375, 667), displayScale: 2, small: (292, 292), medium: (638, 292), large: (638, 636))
    ]

    private static func iPhoneiOS15(
        screenSize: (CGFloat, CGFloat),
        small: (CGFloat, CGFloat),
        medium: (CGFloat, CGFloat),
        large: (CGFloat, CGFloat),
        circular: (CGFloat, CGFloat),
        rectangular: (CGFloat, CGFloat),
        inline: (CGFloat, CGFloat)
    ) -> WidgetFrameSet {
        WidgetFrameSet(
            platform: .phone,
            screenSize: CGSize(width: screenSize.0, height: screenSize.1),
            /// FrameUp supports iOS 15 and later, so the published values are treated as applying from there.
            minMajorOSVersion: 15,
            frames: framesFromPoints([
                .small: small,
                .medium: medium,
                .large: large,
                .accessoryCircular: circular,
                .accessoryRectangular: rectangular,
                .accessoryInline: inline
            ])
        )
    }

    private static func iPhoneiOS26(
        screenSize: (CGFloat, CGFloat),
        displayScale: CGFloat,
        small: (CGFloat, CGFloat),
        medium: (CGFloat, CGFloat),
        large: (CGFloat, CGFloat)
    ) -> WidgetFrameSet {
        WidgetFrameSet(
            platform: .phone,
            screenSize: CGSize(width: screenSize.0, height: screenSize.1),
            minMajorOSVersion: 26,
            displayScale: displayScale,
            frames: framesFromPixels(displayScale: displayScale, [
                .small: small,
                .medium: medium,
                .large: large
            ])
        )
    }
}
