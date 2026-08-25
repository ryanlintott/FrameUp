//
//  WidgetFrameSet+all.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-08-25.
//

import SwiftUI

extension WidgetFrame {
    /// Every known set of widget frames.
    ///
    /// iPhone sets from iOS 26 onward were measured with the `WidgetSizeProbe` widget in the example app. Everything else is sourced from [Apple Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications), which describes iOS 18 and earlier. Spot checks on iOS 18.6 confirmed the published iPhone values, including the 402 and 440 point wide screens that Apple never published a row for.
    static let all: [WidgetFrame] = iPhoneiOS15 + iPhoneiOS15LockScreen + iPhoneiOS26 + iPhoneiOS26LockScreen + iPad + iPadLockScreen + visionOS + watch

    /// iPhone frames for iOS 18 and earlier, as published by Apple.
    ///
    /// These are published values rather than measurements. Three of them were confirmed on iOS 18.6 with the `WidgetSizeProbe` widget and are marked below, including 440x956 and 402x874 which Apple never published a row for. The rest are unverified.
    private static let iPhoneiOS15: [WidgetFrame] = [
        // Confirmed on iPhone 16 Pro Max (iPhone17,2), iOS 18.6, which reports a 440x956 screen and resolves here by nearest width
        iPhoneiOS15(screenSize: (430, 932), small: (170, 170), medium: (364, 170), large: (364, 382)),
        iPhoneiOS15(screenSize: (428, 926), small: (170, 170), medium: (364, 170), large: (364, 382)),
        iPhoneiOS15(screenSize: (414, 896), small: (169, 169), medium: (360, 169), large: (360, 379)),
        iPhoneiOS15(screenSize: (414, 736), small: (159, 159), medium: (348, 157), large: (348, 357)),
        // Confirmed on iPhone 16 Pro (iPhone17,1), iOS 18.6, which reports a 402x874 screen and resolves here by nearest width
        iPhoneiOS15(screenSize: (393, 852), small: (158, 158), medium: (338, 158), large: (338, 354)),
        // Confirmed on iPhone 13 (iPhone14,5), iOS 18.6
        iPhoneiOS15(screenSize: (390, 844), small: (158, 158), medium: (338, 158), large: (338, 354)),
        iPhoneiOS15(screenSize: (375, 812), small: (155, 155), medium: (329, 155), large: (329, 345)),
        iPhoneiOS15(screenSize: (375, 667), small: (148, 148), medium: (321, 148), large: (321, 324)),
        // No device has been observed reporting this screen size. It is likely a Display Zoom mode rather than a device's native size.
        iPhoneiOS15(screenSize: (360, 780), small: (155, 155), medium: (329, 155), large: (329, 345)),
        iPhoneiOS15(screenSize: (320, 568), small: (141, 141), medium: (292, 141), large: (292, 311))
    ].flatMap { $0 }

    private static func iPhoneiOS15(
        screenSize: (CGFloat, CGFloat),
        small: (CGFloat, CGFloat),
        medium: (CGFloat, CGFloat),
        large: (CGFloat, CGFloat)
    ) -> [WidgetFrame] {
        group(
            platform: .phone,
            /// FrameUp supports iOS 15 and later, so the published values are treated as applying from there.
            minMajorOSVersion: 15,
            placement: .homeScreen,
            screenSize: screenSize,
            /// Apple published one value per screen size, and each is a whole pixel at both 2x and 3x, so there is no evidence these split by scale.
            displayScale: nil,
            /// Only iPad has a design canvas separate from its Home Screen frame.
            target: nil,
            frames: [
                .small: small,
                .medium: medium,
                .large: large
            ]
        )
    }

    /// iPhone accessory frames for iOS 18 and earlier, as published by Apple.
    ///
    /// These are the accessory columns of the same published table, separated because accessory widgets appear on the Lock Screen rather than the Home Screen. Accessory widgets arrived in iOS 16, so these apply from there rather than from 15.
    ///
    /// > Note: these have not been measured on iOS 26. The system frames on that OS all changed, so these may be out of date.
    private static let iPhoneiOS15LockScreen: [WidgetFrame] = [
        iPhoneiOS15Lock(screenSize: (430, 932), circular: (76, 76), rectangular: (172, 76), inline: (257, 26)),
        iPhoneiOS15Lock(screenSize: (428, 926), circular: (76, 76), rectangular: (172, 76), inline: (257, 26)),
        iPhoneiOS15Lock(screenSize: (414, 896), circular: (76, 76), rectangular: (160, 72), inline: (248, 26)),
        iPhoneiOS15Lock(screenSize: (414, 736), circular: (76, 76), rectangular: (170, 76), inline: (248, 26)),
        iPhoneiOS15Lock(screenSize: (393, 852), circular: (72, 72), rectangular: (160, 72), inline: (234, 26)),
        iPhoneiOS15Lock(screenSize: (390, 844), circular: (72, 72), rectangular: (160, 72), inline: (234, 26)),
        iPhoneiOS15Lock(screenSize: (375, 812), circular: (72, 72), rectangular: (157, 72), inline: (225, 26)),
        iPhoneiOS15Lock(screenSize: (375, 667), circular: (68, 68), rectangular: (153, 68), inline: (225, 26)),
        iPhoneiOS15Lock(screenSize: (360, 780), circular: (72, 72), rectangular: (157, 72), inline: (225, 26)),
        iPhoneiOS15Lock(screenSize: (320, 568), circular: (72, 72), rectangular: (157, 72), inline: (225, 26))
    ].flatMap { $0 }

    /// The accessory frames from the same published row, recorded against the Lock Screen where they actually appear.
    private static func iPhoneiOS15Lock(
        screenSize: (CGFloat, CGFloat),
        circular: (CGFloat, CGFloat),
        rectangular: (CGFloat, CGFloat),
        inline: (CGFloat, CGFloat)
    ) -> [WidgetFrame] {
        group(
            platform: .phone,
            minMajorOSVersion: 16,
            placement: .lockScreen,
            screenSize: screenSize,
            displayScale: nil,
            target: nil,
            frames: [
                .accessoryCircular: circular,
                .accessoryRectangular: rectangular,
                .accessoryInline: inline
            ]
        )
    }

    /// iPhone frames for iOS 26 and later, measured rather than published.
    ///
    /// Values are written in pixels because every measured frame lands on a whole number of pixels. Dividing by the display scale reproduces the fractional point values exactly. The frames themselves are stored in points.
    ///
    /// > Note: the accessory sizes and `extraLargePortrait` have not been measured on iOS 26 yet, so they are omitted here. Sets layer rather than replace, so a lookup on iOS 26 still returns the published accessory frames from the iOS 15 set. Those values are unverified on iOS 26 and may have changed the way the system sizes did.
    private static let iPhoneiOS26: [WidgetFrame] = [
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
        // extraLargePortrait arrived in iOS 27 and Apple publishes no row for it on any platform. Measured on iPhone 17 (iPhone18,3), iOS 27.0, and on this screen size only, so every other iPhone resolves to it by nearest width and is unverified.
        group(
            platform: .phone,
            minMajorOSVersion: 27,
            placement: .homeScreen,
            screenSize: (402, 874),
            displayScale: 3,
            target: nil,
            frames: framesFromPixels(displayScale: 3, [.extraLargePortrait: (1049, 1697)])
        ),
        // Measured on iPhone 16 (iPhone17,3), iOS 26.5
        iPhoneiOS26(screenSize: (393, 852), displayScale: 3, small: (488, 488), medium: (1034, 488), large: (1034, 1080)),
        // Measured on iPhone 13 (iPhone14,5) and iPhone 17e (iPhone18,5), iOS 26.5 and 27.0
        iPhoneiOS26(screenSize: (390, 844), displayScale: 3, small: (486, 486), medium: (1026, 486), large: (1026, 1074)),
        // Measured on iPhone 11 Pro (iPhone12,3) and iPhone 13 mini (iPhone14,4), iOS 26.5
        iPhoneiOS26(screenSize: (375, 812), displayScale: 3, small: (477, 477), medium: (1001, 477), large: (1001, 1047)),
        // Measured on iPhone SE 3rd generation (iPhone14,6), iOS 26.5
        iPhoneiOS26(screenSize: (375, 667), displayScale: 2, small: (292, 292), medium: (638, 292), large: (638, 636))
    ].flatMap { $0 }

    private static func iPhoneiOS26(
        screenSize: (CGFloat, CGFloat),
        displayScale: CGFloat,
        small: (CGFloat, CGFloat),
        medium: (CGFloat, CGFloat),
        large: (CGFloat, CGFloat)
    ) -> [WidgetFrame] {
        group(
            platform: .phone,
            minMajorOSVersion: 26,
            placement: .homeScreen,
            screenSize: screenSize,
            displayScale: displayScale,
            target: nil,
            frames: framesFromPixels(displayScale: displayScale, [
                .small: small,
                .medium: medium,
                .large: large
            ])
        )
    }

    /// iPhone accessory frames for iOS 26 and later, measured rather than published.
    ///
    /// These changed in iOS 26 the way the system frames did, and by more in relative terms. On a 402x874 iPhone `accessoryInline` is 342 points wide where Apple publishes 234, which is 46 percent wider.
    ///
    /// Every iPhone screen size that iOS 26 supports has been measured. `accessoryInline` is 36 points tall on every one of them, where Apple publishes 26.
    ///
    /// Values are written in pixels for the same reason as the system frames, and 414x896 splits by display scale here too.
    private static let iPhoneiOS26LockScreen: [WidgetFrame] = [
        // Measured on iPhone 17 Pro Max (iPhone18,2), iOS 26.5
        iPhoneiOS26Lock(screenSize: (440, 956), displayScale: 3, circular: (180, 180), rectangular: (474, 180), inline: (1110, 108)),
        // Measured on iPhone 16 Plus (iPhone17,4), iOS 26.5
        iPhoneiOS26Lock(screenSize: (430, 932), displayScale: 3, circular: (180, 180), rectangular: (474, 180), inline: (1110, 108)),
        // Measured on iPhone 13 Pro Max (iPhone14,3), iOS 26.5
        iPhoneiOS26Lock(screenSize: (428, 926), displayScale: 3, circular: (180, 180), rectangular: (468, 180), inline: (1092, 108)),
        // Measured on iPhone Air (iPhone18,4), iOS 26.5
        iPhoneiOS26Lock(screenSize: (420, 912), displayScale: 3, circular: (173, 173), rectangular: (459, 173), inline: (1080, 108)),
        // Measured on iPhone 11 Pro Max (iPhone12,5), iOS 26.5. Also the iPhone XS Max.
        iPhoneiOS26Lock(screenSize: (414, 896), displayScale: 3, circular: (191, 191), rectangular: (470, 191), inline: (1074, 108)),
        // Measured on iPhone 11 (iPhone12,1), iOS 26.5. Also the iPhone XR. Same screen size as the row above but at 2x, and the frames differ.
        iPhoneiOS26Lock(screenSize: (414, 896), displayScale: 2, circular: (120, 120), rectangular: (308, 120), inline: (716, 72)),
        // Measured on iPhone 17 (iPhone18,3), iOS 27.0
        iPhoneiOS26Lock(screenSize: (402, 874), displayScale: 3, circular: (174, 174), rectangular: (444, 174), inline: (1026, 108)),
        // Measured on iPhone 16 (iPhone17,3), iOS 26.5
        iPhoneiOS26Lock(screenSize: (393, 852), displayScale: 3, circular: (174, 174), rectangular: (443, 174), inline: (1023, 108)),
        // Measured on iPhone 17e (iPhone18,5), iOS 26.5
        iPhoneiOS26Lock(screenSize: (390, 844), displayScale: 3, circular: (174, 174), rectangular: (438, 174), inline: (1008, 108)),
        // Measured on iPhone 11 Pro (iPhone12,3), iOS 26.5
        iPhoneiOS26Lock(screenSize: (375, 812), displayScale: 3, circular: (174, 174), rectangular: (429, 174), inline: (981, 108)),
        // Measured on iPhone SE 3rd generation (iPhone14,6), iOS 26.5
        iPhoneiOS26Lock(screenSize: (375, 667), displayScale: 2, circular: (112, 112), rectangular: (282, 112), inline: (646, 72))
    ].flatMap { $0 }

    private static func iPhoneiOS26Lock(
        screenSize: (CGFloat, CGFloat),
        displayScale: CGFloat,
        circular: (CGFloat, CGFloat),
        rectangular: (CGFloat, CGFloat),
        inline: (CGFloat, CGFloat)
    ) -> [WidgetFrame] {
        group(
            platform: .phone,
            minMajorOSVersion: 26,
            placement: .lockScreen,
            screenSize: screenSize,
            displayScale: displayScale,
            target: nil,
            frames: framesFromPixels(displayScale: displayScale, [
                .accessoryCircular: circular,
                .accessoryRectangular: rectangular,
                .accessoryInline: inline
            ])
        )
    }

    /// visionOS frames, as published by Apple.
    ///
    /// visionOS widgets are placed on real surfaces rather than a screen, so there is no screen size to key on and one group covers every device. The screen size is a placeholder that any lookup matches.
    ///
    /// > Note: `accessoryCircular` and `accessoryRectangular` are supported from visionOS 27 but have no frame here yet, so they are omitted.
    private static let visionOS: [WidgetFrame] = group(
        platform: .vision,
        minMajorOSVersion: 1,
        placement: .homeScreen,
        screenSize: (0, 0),
        displayScale: nil,
        target: nil,
        frames: [
            .small: (158, 158),
            .medium: (338, 158),
            .large: (338, 354),
            .extraLarge: (450, 338),
            .extraLargePortrait: (338, 450)
        ]
    )

    /// Screen size and case size in millimetres for every Apple Watch.
    ///
    /// The one place either fact is written down. The frames below and ``WidgetSize/watchSize(screenSize:)`` both read it.
    static let watchDevices: [(screenSize: CGSize, caseSize: CGFloat)] = [
        (CGSize(width: 136, height: 170), 38),
        (CGSize(width: 156, height: 195), 42),   // Series 1 to 3
        (CGSize(width: 162, height: 197), 40),
        (CGSize(width: 176, height: 215), 41),
        (CGSize(width: 184, height: 224), 44),
        (CGSize(width: 187, height: 223), 42),   // Series 10 and 11
        (CGSize(width: 198, height: 242), 45),
        (CGSize(width: 205, height: 251), 49),   // Ultra and Ultra 2
        (CGSize(width: 208, height: 248), 46),   // Series 10 and 11
        (CGSize(width: 211, height: 257), 49)    // Ultra 3
    ]

    /// Apple Watch Smart Stack frames, as published by Apple, keyed on case size the way Apple publishes them.
    ///
    /// Each entry applies from its case size upward, so a case size larger than any Apple Watch yet released takes the largest frame.
    ///
    /// > Note: `accessoryCircular` and `accessoryInline` are supported on Apple Watch but have no frame here yet, so they are omitted. `accessoryCorner` is supported too but has no ``WidgetSize`` case.
    static let watchRectangularByCaseSize: [(minCaseSize: CGFloat, frame: CGSize)] = [
        (49, CGSize(width: 191, height: 81.5)),
        (45, CGSize(width: 184, height: 80.5)),
        (44, CGSize(width: 173, height: 76.5)),
        (41, CGSize(width: 165, height: 72.5)),
        (0, CGSize(width: 152, height: 69.5))
    ]

    /// The Smart Stack frame for a case size in millimetres.
    static func watchRectangular(caseSize: CGFloat) -> CGSize? {
        watchRectangularByCaseSize.first { caseSize >= $0.minCaseSize }?.frame
    }

    /// Apple Watch frames, derived by giving each watch the frame published for its case size.
    ///
    /// Storing them against screen size means a watch released after ``watchDevices`` was last updated resolves to the nearest known one rather than to nothing.
    private static let watch: [WidgetFrame] = watchDevices.flatMap { device -> [WidgetFrame] in
        guard let frame = watchRectangular(caseSize: device.caseSize) else { return [] }
        return group(
            platform: .watch,
            /// FrameUp supports watchOS 9 and later, which is also where widgets in the Smart Stack arrived.
            minMajorOSVersion: 9,
            placement: .smartStack,
            screenSize: (device.screenSize.width, device.screenSize.height),
            displayScale: nil,
            target: nil,
            frames: [.accessoryRectangular: (frame.width, frame.height)]
        )
    }

    /// iPad frames, as published by Apple.
    ///
    /// Each screen size contributes two sets, one for the design canvas the content is laid out in and one for the smaller Home Screen frame the canvas is scaled into. The 820x1180 canvas values are confirmed by measurement on iPadOS 18.6, 26.5 and 27.0, and its Home Screen value of 136 points is confirmed by measuring a placed widget on screen. iPad frames did not change in iOS 26, so unlike iPhone these apply from iOS 15 with no later set.
    ///
    /// > Note: `extraLargePortrait` is supported on iPad from iOS 27 but has no frame here yet, so it is omitted.
    private static let iPad: [WidgetFrame] = [
        iPadFrameSet(screenSize: (1192, 1590), canvas: ((188, 188), (412, 188), (412, 412), (860, 412)), homeScreen: ((188, 188), (412, 188), (412, 412), (860, 412))),
        iPadFrameSet(screenSize: (1024, 1366), canvas: ((170, 170), (378.5, 170), (378.5, 378.5), (795, 378.5)), homeScreen: ((160, 160), (356, 160), (356, 356), (748, 356))),
        iPadFrameSet(screenSize: (970, 1389), canvas: ((162, 162), (350, 162), (350, 350), (726, 350)), homeScreen: ((162, 162), (350, 162), (350, 350), (726, 350))),
        iPadFrameSet(screenSize: (954, 1373), canvas: ((162, 162), (350, 162), (350, 350), (726, 350)), homeScreen: ((162, 162), (350, 162), (350, 350), (726, 350))),
        iPadFrameSet(screenSize: (834, 1194), canvas: ((155, 155), (342, 155), (342, 342), (715.5, 342)), homeScreen: ((136, 136), (300, 136), (300, 300), (628, 300))),
        iPadFrameSet(screenSize: (834, 1112), canvas: ((150, 150), (327.5, 150), (327.5, 327.5), (682, 327.5)), homeScreen: ((132, 132), (288, 132), (288, 288), (600, 288))),
        // Canvas values confirmed on iPad Air 11-inch M2 (iPad14,9) on iPadOS 18.6 and 26.5, and iPad A16 (iPad15,7) on 27.0. The 136 point Home Screen frame confirmed by measuring a placed widget at 272 pixels.
        iPadFrameSet(screenSize: (820, 1180), canvas: ((155, 155), (342, 155), (342, 342), (715.5, 342)), homeScreen: ((136, 136), (300, 136), (300, 300), (628, 300))),
        iPadFrameSet(screenSize: (810, 1080), canvas: ((146, 146), (320.5, 146), (320.5, 320.5), (669, 320.5)), homeScreen: ((124, 124), (272, 124), (272, 272), (568, 272))),
        iPadFrameSet(screenSize: (768, 1024), canvas: ((141, 141), (305.5, 141), (305.5, 305.5), (634.5, 305.5)), homeScreen: ((120, 120), (260, 120), (260, 260), (540, 260))),
        // Published by Apple with the same values as 768x1024. The switch this table replaced had no row for it and reached the same values through its default arm.
        iPadFrameSet(screenSize: (744, 1133), canvas: ((141, 141), (305.5, 141), (305.5, 305.5), (634.5, 305.5)), homeScreen: ((120, 120), (260, 120), (260, 260), (540, 260)))
    ].flatMap { $0 }

    /// Builds the design canvas and Home Screen sets for one iPad screen size.
    private static func iPadFrameSet(
        screenSize: (CGFloat, CGFloat),
        canvas: ((CGFloat, CGFloat), (CGFloat, CGFloat), (CGFloat, CGFloat), (CGFloat, CGFloat)),
        homeScreen: ((CGFloat, CGFloat), (CGFloat, CGFloat), (CGFloat, CGFloat), (CGFloat, CGFloat))
    ) -> [WidgetFrame] {
        [(WidgetTarget.designCanvas, canvas), (.homeScreen, homeScreen)].flatMap { target, sizes in
            group(
                platform: .pad,
                minMajorOSVersion: 15,
                placement: .homeScreen,
                screenSize: screenSize,
                displayScale: nil,
                target: target,
                frames: [
                    .small: sizes.0,
                    .medium: sizes.1,
                    .large: sizes.2,
                    .extraLarge: sizes.3
                ]
            )
        }
    }


    /// iPad Lock Screen frames, measured rather than published. Apple's table has no accessory row for iPad at all.
    ///
    /// A `systemSmall` on the iPad Lock Screen is 152x152 rather than the 155x155 it is on the Home Screen. 152 points is also the width of `accessoryRectangular`, so the Lock Screen widget column appears to be 152 points wide with a system small sized to fit it.
    ///
    /// > Note: only one iPad screen size has been measured. Every other iPad resolves to these values by nearest width, which is unverified. iPad Lock Screen widgets arrived in iPadOS 17 but the earliest measurement is on 18.6, so these apply from 18.
    private static let iPadLockScreen: [WidgetFrame] = [
        // Measured on iPad Air 11-inch M2 (iPad14,9), iPadOS 18.6 and 26.5
        group(
            platform: .pad,
            minMajorOSVersion: 18,
            placement: .lockScreen,
            screenSize: (820, 1180),
            displayScale: nil,
            target: .designCanvas,
            frames: [
                .small: (152, 152),
                .accessoryCircular: (63, 63),
                .accessoryRectangular: (152, 63),
                .accessoryInline: (372, 36)
            ]
        )
    ].flatMap { $0 }
}
