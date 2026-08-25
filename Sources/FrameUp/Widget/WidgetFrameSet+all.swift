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
    static let all: [WidgetFrameSet] = iPhoneLegacy + iPhoneModern

    /// iPhone frames for iOS 18 and earlier, as published by Apple.
    ///
    /// > Note: `extraLargePortrait` is supported on iPhone from iOS 27 but has no frame here yet, so it is omitted.
    private static let iPhoneLegacy: [WidgetFrameSet] = [
        phoneLegacy(430, 932, small: (170, 170), medium: (364, 170), large: (364, 382), circular: (76, 76), rectangular: (172, 76), inline: (257, 26)),
        phoneLegacy(428, 926, small: (170, 170), medium: (364, 170), large: (364, 382), circular: (76, 76), rectangular: (172, 76), inline: (257, 26)),
        phoneLegacy(414, 896, small: (169, 169), medium: (360, 169), large: (360, 379), circular: (76, 76), rectangular: (160, 72), inline: (248, 26)),
        phoneLegacy(414, 736, small: (159, 159), medium: (348, 157), large: (348, 357), circular: (76, 76), rectangular: (170, 76), inline: (248, 26)),
        phoneLegacy(393, 852, small: (158, 158), medium: (338, 158), large: (338, 354), circular: (72, 72), rectangular: (160, 72), inline: (234, 26)),
        phoneLegacy(390, 844, small: (158, 158), medium: (338, 158), large: (338, 354), circular: (72, 72), rectangular: (160, 72), inline: (234, 26)),
        phoneLegacy(375, 812, small: (155, 155), medium: (329, 155), large: (329, 345), circular: (72, 72), rectangular: (157, 72), inline: (225, 26)),
        phoneLegacy(375, 667, small: (148, 148), medium: (321, 148), large: (321, 324), circular: (68, 68), rectangular: (153, 68), inline: (225, 26)),
        phoneLegacy(360, 780, small: (155, 155), medium: (329, 155), large: (329, 345), circular: (72, 72), rectangular: (157, 72), inline: (225, 26)),
        phoneLegacy(320, 568, small: (141, 141), medium: (292, 141), large: (292, 311), circular: (72, 72), rectangular: (157, 72), inline: (225, 26))
    ]

    /// iPhone frames for iOS 26 and later, measured rather than published.
    ///
    /// Values are given in pixels because every measured frame lands on a whole number of pixels. Dividing by the scale factor reproduces the fractional point values exactly.
    ///
    /// > Note: the accessory sizes and `extraLargePortrait` have not been measured on iOS 26 yet, so they are omitted and a lookup falls back to no frame rather than an iOS 18 value that is known to be wrong for the system sizes.
    private static let iPhoneModern: [WidgetFrameSet] = [
        phoneModern(440, 956, scale: 3, small: (530, 530), medium: (1134, 530), large: (1134, 1182)),
        phoneModern(430, 932, scale: 3, small: (524, 524), medium: (1116, 524), large: (1116, 1164)),
        phoneModern(428, 926, scale: 3, small: (523, 523), medium: (1115, 523), large: (1115, 1161)),
        phoneModern(420, 912, scale: 3, small: (518, 518), medium: (1100, 518), large: (1100, 1146)),
        phoneModern(414, 896, scale: 2, small: (333, 333), medium: (712, 333), large: (712, 743)),
        phoneModern(402, 874, scale: 3, small: (493, 493), medium: (1049, 493), large: (1049, 1095)),
        phoneModern(393, 852, scale: 3, small: (488, 488), medium: (1034, 488), large: (1034, 1080)),
        phoneModern(390, 844, scale: 3, small: (486, 486), medium: (1026, 486), large: (1026, 1074)),
        phoneModern(375, 812, scale: 3, small: (477, 477), medium: (1001, 477), large: (1001, 1047)),
        phoneModern(375, 667, scale: 2, small: (292, 292), medium: (638, 292), large: (638, 636))
    ]

    private static func phoneLegacy(
        _ width: CGFloat,
        _ height: CGFloat,
        small: (CGFloat, CGFloat),
        medium: (CGFloat, CGFloat),
        large: (CGFloat, CGFloat),
        circular: (CGFloat, CGFloat),
        rectangular: (CGFloat, CGFloat),
        inline: (CGFloat, CGFloat)
    ) -> WidgetFrameSet {
        WidgetFrameSet(
            platform: .phone,
            screenSize: CGSize(width: width, height: height),
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

    private static func phoneModern(
        _ width: CGFloat,
        _ height: CGFloat,
        scale: CGFloat,
        small: (CGFloat, CGFloat),
        medium: (CGFloat, CGFloat),
        large: (CGFloat, CGFloat)
    ) -> WidgetFrameSet {
        WidgetFrameSet(
            platform: .phone,
            screenSize: CGSize(width: width, height: height),
            minMajorOSVersion: 26,
            frames: framesFromPixels(scale: scale, [
                .small: small,
                .medium: medium,
                .large: large
            ])
        )
    }
}
