//
//  WidgetFrameRecord+all.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-08-25.
//

import SwiftUI

extension WidgetFrameRecord {
    /// Every known set of widget frames.
    ///
    /// iPhone sets from iOS 26 onward were measured with the `WidgetSizeProbe` widget in the example app. Everything else is sourced from [Apple Human Interface Guidelines: widget specifications](https://developer.apple.com/design/human-interface-guidelines/widgets#Specifications), which describes iOS 18 and earlier. Spot checks on iOS 18.6 confirmed the published iPhone values, including the 402 and 440 point wide screens that Apple never published a row for.
    static let all: [WidgetFrameRecord] = iPhoneiOS15 + iPhoneiOS15LockScreen + iPhoneiOS26 + iPhoneiOS26LockScreen + iPhoneiOS27Portrait + iPadDesignCanvas + iPadHomeScreen + iPadPortraitDesignCanvas + iPadPortraitHomeScreen + iPadLockScreen + visionOS + visionOSAccessory + watch + mac

    /// iPhone frames for iOS 18 and earlier, as published by Apple.
    ///
    /// These are published values rather than measurements. Three of them were confirmed on iOS 18.6 with the `WidgetSizeProbe` widget and are marked below, including 440x956 and 402x874 which Apple never published a row for. The rest are unverified.
    private static let iPhoneiOS15: [WidgetFrameRecord] = [
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
    ) -> [WidgetFrameRecord] {
        group(
            platform: .phone,
            /// FrameUp supports iOS 15 and later, so the published values are treated as applying from there.
            minMajorOSVersion: 15,
            placement: .homeScreen,
            screenSize: screenSize,
            /// Apple published one value per screen size, and each is a whole pixel at both 2x and 3x, so there is no evidence these split by scale.
            displayScale: nil,
            /// Every platform lays out on a design canvas. Only the iPad Home Screen scales it into a smaller slot, so only iPad has `.homeScreen` rows.
            target: .designCanvas,
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
    /// > Note: these are superseded from iOS 26 by ``iPhoneiOS26LockScreen``, which measured every one of them and found every published value wrong. They still apply to iOS 18 and earlier, where they remain unverified.
    private static let iPhoneiOS15LockScreen: [WidgetFrameRecord] = [
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
    ) -> [WidgetFrameRecord] {
        group(
            platform: .phone,
            minMajorOSVersion: 16,
            placement: .lockScreen,
            screenSize: screenSize,
            displayScale: nil,
            target: .designCanvas,
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
    /// > Note: only the system sizes are here. The accessory sizes changed in iOS 26 too and are in ``iPhoneiOS26LockScreen``, kept separate because they appear on the Lock Screen rather than the Home Screen. `extraLargePortrait` does not exist until iOS 27 and is in ``iPhoneiOS27Portrait``.
    private static let iPhoneiOS26: [WidgetFrameRecord] = [
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
    ].flatMap { $0 }

    private static func iPhoneiOS26(
        screenSize: (CGFloat, CGFloat),
        displayScale: CGFloat,
        small: (CGFloat, CGFloat),
        medium: (CGFloat, CGFloat),
        large: (CGFloat, CGFloat)
    ) -> [WidgetFrameRecord] {
        group(
            platform: .phone,
            minMajorOSVersion: 26,
            placement: .homeScreen,
            screenSize: screenSize,
            displayScale: displayScale,
            target: .designCanvas,
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
    private static let iPhoneiOS26LockScreen: [WidgetFrameRecord] = [
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
    ) -> [WidgetFrameRecord] {
        group(
            platform: .phone,
            minMajorOSVersion: 26,
            placement: .lockScreen,
            screenSize: screenSize,
            displayScale: displayScale,
            target: .designCanvas,
            frames: framesFromPixels(displayScale: displayScale, [
                .accessoryCircular: circular,
                .accessoryRectangular: rectangular,
                .accessoryInline: inline
            ])
        )
    }

    /// iPhone `extraLargePortrait` frames, measured rather than published. Apple publishes no row for this family on any platform.
    ///
    /// Every iPhone screen size that iOS 27 supports has been measured, and every one of them offers the family, including the smallest.
    ///
    /// On every device the width is identical to `systemMedium` and `systemLarge`, so this is the same column made taller rather than a differently proportioned frame. 414x896 splits by display scale here as it does for the system and accessory frames.
    private static let iPhoneiOS27Portrait: [WidgetFrameRecord] = [
        // Measured on iPhone 17 Pro Max (iPhone18,2), iOS 27.0
        iPhoneiOS27Portrait(screenSize: (440, 956), displayScale: 3, portrait: (1134, 1834)),
        // Measured on iPhone 16 Plus (iPhone17,4), iOS 27.0
        iPhoneiOS27Portrait(screenSize: (430, 932), displayScale: 3, portrait: (1116, 1804)),
        // Measured on iPhone 13 Pro Max (iPhone14,3), iOS 27.0
        iPhoneiOS27Portrait(screenSize: (428, 926), displayScale: 3, portrait: (1115, 1799)),
        // Measured on iPhone Air (iPhone18,4), iOS 27.0
        iPhoneiOS27Portrait(screenSize: (420, 912), displayScale: 3, portrait: (1100, 1774)),
        // Measured on iPhone 11 Pro Max (iPhone12,5), iOS 27.0. Also the iPhone XS Max.
        iPhoneiOS27Portrait(screenSize: (414, 896), displayScale: 3, portrait: (1088, 1754)),
        // Measured on iPhone 11 (iPhone12,1), iOS 27.0. Also the iPhone XR.
        iPhoneiOS27Portrait(screenSize: (414, 896), displayScale: 2, portrait: (712, 1153)),
        // Measured on iPhone 17 (iPhone18,3), iOS 27.0
        iPhoneiOS27Portrait(screenSize: (402, 874), displayScale: 3, portrait: (1049, 1697)),
        // Measured on iPhone 16 (iPhone17,3), iOS 27.0
        iPhoneiOS27Portrait(screenSize: (393, 852), displayScale: 3, portrait: (1034, 1672)),
        // Measured on iPhone 17e (iPhone18,5), iOS 27.0
        iPhoneiOS27Portrait(screenSize: (390, 844), displayScale: 3, portrait: (1026, 1662)),
        // Measured on iPhone 11 Pro (iPhone12,3), iOS 27.0
        iPhoneiOS27Portrait(screenSize: (375, 812), displayScale: 3, portrait: (1001, 1617)),
        // Measured on iPhone SE 3rd generation (iPhone14,6), iOS 27.0
        iPhoneiOS27Portrait(screenSize: (375, 667), displayScale: 2, portrait: (638, 980))
    ].flatMap { $0 }

    private static func iPhoneiOS27Portrait(
        screenSize: (CGFloat, CGFloat),
        displayScale: CGFloat,
        portrait: (CGFloat, CGFloat)
    ) -> [WidgetFrameRecord] {
        group(
            platform: .phone,
            minMajorOSVersion: 27,
            placement: .homeScreen,
            screenSize: screenSize,
            displayScale: displayScale,
            target: .designCanvas,
            frames: framesFromPixels(displayScale: displayScale, [.extraLargePortrait: portrait])
        )
    }

    /// visionOS system frames, measured rather than published.
    ///
    /// visionOS widgets are placed on real surfaces rather than a screen, so there is no screen size to key on and one group covers every device. The screen size is a placeholder that any lookup matches.
    ///
    /// Apple publishes a visionOS row, but only `small` matches what the system reports. Measured on visionOS 26.5 and 27.0, which agree exactly, so this is a published table that was never right rather than a frame that changed. The published `medium` and `large` are 338 wide against a measured 354, and the published `extraLarge` is 450x338 against a measured 550x354.
    ///
    /// The measured frames form a grid of 158 point cells with a 38 point gutter, so one, two and three cells are 158, 354 and 550 points. Every system frame lands on it: `medium` is two cells by one, `extraLarge` three by two, and `extraLargePortrait` the same two by three the other way up.
    ///
    /// Apple's table contradicts itself, and the one place it disagrees with itself is the place it agrees with the measurement. It publishes `large` as 338x354, which cannot be right because a two by two widget has to be square. Every other two cell span in the table is written 338, but `large`'s height is written 354, which is what every two cell span measures.
    ///
    /// Read from the widget gallery, and a widget placed on a surface was checked against its preview and matched, the same result as on iPhone and iPad.
    ///
    /// Widgets arrived on visionOS in version 26, so these are not an earlier version's frames: every visionOS availability annotation in WidgetKit is 26.0 or 27.0, and a widget extension does not compile for visionOS 2 at all. The published table even has an `extraLargePortrait` row, a family that is visionOS 26.0 in the SDK.
    private static let visionOS: [WidgetFrameRecord] = group(
        platform: .vision,
        minMajorOSVersion: 26,
        placement: .homeScreen,
        screenSize: (0, 0),
        displayScale: nil,
        target: .designCanvas,
        frames: [
            .small: (158, 158),
            .medium: (354, 158),
            .large: (354, 354),
            .extraLarge: (550, 354),
            .extraLargePortrait: (354, 550)
        ]
    )

    /// visionOS accessory frames, measured rather than published. Apple publishes no accessory row for visionOS.
    ///
    /// Added in visionOS 27, and absent from a 26.5 sweep that offered every other family, which confirms the version they arrive in. The visionOS SDK has no `accessoryInline` case at all, so only these two exist.
    ///
    /// Unlike the system frames these do not land on the 158 point grid. They are recorded against the Home Screen because visionOS has no Lock Screen: they render with a container background and report `isPreview` false, the same as every other visionOS family, rather than the backgroundless vibrant render an iPhone Lock Screen accessory gives.
    private static let visionOSAccessory: [WidgetFrameRecord] = group(
        platform: .vision,
        minMajorOSVersion: 27,
        placement: .homeScreen,
        screenSize: (0, 0),
        displayScale: nil,
        target: .designCanvas,
        frames: [
            .accessoryCircular: (75, 75),
            .accessoryRectangular: (208, 79)
        ]
    )

    /// macOS frames, measured rather than published. Apple publishes no widget specifications for macOS at all.
    ///
    /// Measured on macOS 26.6 with the widget in Notification Center. A Mac widget is not placed on a screen grid the way an iPhone widget is, so like visionOS there is no screen size to key on and the screen size is a placeholder that any lookup matches. The same widgets were confirmed to report the same frames on two displays of very different point sizes.
    ///
    /// The frames form a clean grid with a 16 point gutter: `medium` is two `small` plus a gutter, and `extraLarge` is two `large` plus a gutter.
    ///
    /// > Note: measured on macOS 26 only, so they apply from there. Earlier versions report no frame rather than a value that may not hold, since iOS frames are known to have changed in its version 26. `extraLargePortrait` arrives in macOS 27 and has not been measured. The accessory sizes do not exist on macOS.
    private static let mac: [WidgetFrameRecord] = group(
        platform: .mac,
        minMajorOSVersion: 26,
        placement: .homeScreen,
        screenSize: (0, 0),
        displayScale: nil,
        target: .designCanvas,
        frames: [
            .small: (164, 164),
            .medium: (344, 164),
            .large: (344, 344),
            .extraLarge: (704, 344)
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
        (CGSize(width: 187, height: 223), 42),   // Series 10, 11 and 12
        (CGSize(width: 198, height: 242), 45),
        (CGSize(width: 205, height: 251), 49),   // Ultra and Ultra 2
        (CGSize(width: 208, height: 248), 46),   // Series 10, 11 and 12
        (CGSize(width: 211, height: 257), 49)    // Ultra 3 and Ultra 4
    ]

    /// Apple Watch Smart Stack frames, as published by Apple, keyed on case size the way Apple publishes them.
    ///
    /// These are exactly the rows Apple publishes, so the list can be checked against the specification line by line.
    ///
    /// These are the published Smart Stack values only. ``watchMeasured`` supersedes them for every watch with a simulator, and they remain the fallback for the rest.
    ///
    /// > Note: keyed on case size because that is how Apple publishes them, but a case size does not identify a watch: the Ultra 2 and Ultra 3 are both 49mm with different screens and different frames.
    static let watchRectangularByCaseSize: [(minCaseSize: CGFloat, frame: CGSize)] = [
        (49, CGSize(width: 191, height: 81.5)),
        (45, CGSize(width: 184, height: 80.5)),
        (44, CGSize(width: 173, height: 76.5)),
        (41, CGSize(width: 165, height: 72.5)),
        (40, CGSize(width: 152, height: 69.5))
    ]

    /// The Smart Stack frame for a case size in millimetres.
    ///
    /// A case larger than any Apple publishes takes the largest frame, and one smaller than any Apple publishes takes the smallest. The 38mm Apple Watch is the only real device below the published range, and it takes the 40mm frame.
    ///
    /// The result does not depend on the order of ``watchRectangularByCaseSize``.
    static func watchRectangular(caseSize: CGFloat) -> CGSize? {
        let applicable = watchRectangularByCaseSize.filter { caseSize >= $0.minCaseSize }
        if let largest = applicable.max(by: { $0.minCaseSize < $1.minCaseSize }) {
            return largest.frame
        }
        return watchRectangularByCaseSize.min(by: { $0.minCaseSize < $1.minCaseSize })?.frame
    }

    /// Apple Watch frames measured on watchOS 27, keyed on screen size.
    ///
    /// Apple publishes one Smart Stack frame per case size and nothing else. Measuring found three problems with that. The published table has no row for the 42mm and 46mm Series 10 and 11 watches, so they resolved to a row meant for a smaller watch. It has no watch face row at all, and a complication is a different size from a Smart Stack widget on the same watch. And case size does not determine the frame: the Ultra 2 and Ultra 3 are both 49mm but report 205x251 and 211x257 screens, so they cannot share a row.
    ///
    /// Every family is pre-rendered at two frames during registration, and nothing readable at render time says which place a render came from. `showsWidgetLabel` does not separate them and neither does `disfavoredLocations`, which changes where a widget is offered but not what gets pre-rendered.
    ///
    /// The placement of each frame was established by placing the probe, on every watch here. A widget in the Smart Stack reports the smaller frame of the pair and the same widget as a complication reports the larger, and where a watch was placed in both locations it reported both frames. Every Smart Stack frame matches Apple's published row where Apple publishes one.
    ///
    /// The 42mm is why that is a habit rather than a law. Its two pre-rendered rectangular frames are the same size, and a placed complication confirms the watch face and the Smart Stack really are both 176x72.5. A watch face frame is therefore not always larger than its Smart Stack frame, so nothing asserts that it is.
    ///
    /// Nothing in this table is inferred any more, so a new watch is the only reason to reach for the rule again. `Measurements/watchplacement.swift` is how a row gets settled instead, and `Measurements/README.md` says what a run needs.
    ///
    /// > Note: `accessoryInline` reports a small square, 11x11 to 13.5x13.5, that never renders and is not a usable frame, so it is left out.
    ///
    /// > Note: `accessoryCorner` has a ``WidgetSize`` case but no frame here. It is measured, and the values are in `Measurements/`, but a corner complication is not a rectangle: it sits in the curve of the bezel, roughly triangular, and a label can curve around the frame and extend past it. The reported size is therefore not a box the content fits inside, which is what every other frame in this table means. It also explains why the values do not scale with the screen the way every other family does, 32 on a 162 point wide watch against 30 on a 187.
    ///
    /// > Note: `watchFaceRectangular` is optional for a watch that has been swept but never placed, which leaves it with a Smart Stack frame of its own and a watch face lookup that falls back to the nearest watch that has one.
    private static let watchMeasured: [(screenSize: (CGFloat, CGFloat), smartStackRectangular: (CGFloat, CGFloat), watchFaceRectangular: (CGFloat, CGFloat)?, watchFaceCircular: (CGFloat, CGFloat))] = [
        // Apple Watch SE 3 40mm. Both frames confirmed by placing the probe in both places, and the Smart Stack frame matches Apple's published 40mm row.
        (screenSize: (162, 197), smartStackRectangular: (152, 69.5), watchFaceRectangular: (162, 69), watchFaceCircular: (42, 42)),
        // Apple Watch Series 11 and Series 12 42mm. Apple publishes no row for this case size. Both frames confirmed by placing the probe, and they are the same: a rectangular complication on the watch face is 176x72.5, exactly what the Smart Stack reports. Its pair is pre-rendered twice at that size, which earlier sweeps mistook for a single frame.
        (screenSize: (187, 223), smartStackRectangular: (176, 72.5), watchFaceRectangular: (176, 72.5), watchFaceCircular: (47, 47)),
        // Apple Watch SE 3 44mm. Both frames confirmed by placing the probe, and the Smart Stack frame matches Apple's published 44mm row. Its corner frame is confirmed by a placed widget too.
        (screenSize: (184, 224), smartStackRectangular: (173, 76.5), watchFaceRectangular: (184, 78), watchFaceCircular: (47, 47)),
        // Apple Watch Series 11 and Series 12 46mm. Apple publishes no row for this case size. Both frames confirmed by placing the probe in each place in turn.
        (screenSize: (208, 248), smartStackRectangular: (194, 80.5), watchFaceRectangular: (196, 80.5), watchFaceCircular: (51, 51)),
        // Apple Watch Ultra 3 and Ultra 4 49mm. Apple's published 49mm row describes the Ultra 2, which has a smaller screen in the same case. The watch face frames are confirmed by placed complications reporting 199x84.5 and 51x51, which leaves 197x84, the other half of the pre-rendered pair, as the Smart Stack frame.
        (screenSize: (211, 257), smartStackRectangular: (197, 84), watchFaceRectangular: (199, 84.5), watchFaceCircular: (51, 51))
    ]

    /// Apple Watch frames.
    ///
    /// A measured watch takes its measured frames. Every other watch keeps the frame Apple publishes for its case size, in the Smart Stack only, since there is nothing published for the watch face.
    ///
    /// Storing them against screen size means a watch released after ``watchDevices`` was last updated resolves to the nearest known one rather than to nothing.
    private static let watch: [WidgetFrameRecord] = {
        let measured = watchMeasured.flatMap { row -> [WidgetFrameRecord] in
            var watchFace: [WidgetSize: (CGFloat, CGFloat)] = [.accessoryCircular: row.watchFaceCircular]
            if let rectangular = row.watchFaceRectangular {
                watchFace[.accessoryRectangular] = rectangular
            }
            return group(
                platform: .watch,
                minMajorOSVersion: 9,
                placement: .smartStack,
                screenSize: row.screenSize,
                displayScale: nil,
                target: .designCanvas,
                frames: [.accessoryRectangular: row.smartStackRectangular]
            ) + group(
                platform: .watch,
                minMajorOSVersion: 9,
                placement: .watchFace,
                screenSize: row.screenSize,
                displayScale: nil,
                target: .designCanvas,
                frames: watchFace
            )
        }

        let published = watchDevices.flatMap { device -> [WidgetFrameRecord] in
            /// `CGSize` is only `Hashable` from macOS 15, so this compares rather than using a set.
            let isMeasured = watchMeasured.contains {
                $0.screenSize.0 == device.screenSize.width && $0.screenSize.1 == device.screenSize.height
            }
            guard !isMeasured, let frame = watchRectangular(caseSize: device.caseSize) else { return [] }
            return group(
                platform: .watch,
                /// FrameUp supports watchOS 9 and later, which is also where widgets in the Smart Stack arrived.
                minMajorOSVersion: 9,
                placement: .smartStack,
                screenSize: (device.screenSize.width, device.screenSize.height),
                displayScale: nil,
                target: .designCanvas,
                frames: [.accessoryRectangular: (frame.width, frame.height)]
            )
        }

        return measured + published
    }()

    /// iPad design canvas frames, as published by Apple.
    ///
    /// The design canvas is the frame widget content is laid out in, before the system scales it into the smaller slot the Home Screen grid gives it. ``iPadHomeScreen`` holds the scaled frames.
    ///
    /// iPad frames did not change in iOS 26, so unlike iPhone these apply from iOS 15 with no later set.
    ///
    /// > Note: only the system sizes are here. `extraLargePortrait` arrives in iPadOS 27 and is in ``iPadPortrait``, and the accessory sizes and the Lock Screen `small` frame are in ``iPadLockScreen``.
    private static let iPadDesignCanvas: [WidgetFrameRecord] = [
        iPadDesignCanvas(screenSize: (1192, 1590), small: (188, 188), medium: (412, 188), large: (412, 412), extraLarge: (860, 412)),
        iPadDesignCanvas(screenSize: (1024, 1366), small: (170, 170), medium: (378.5, 170), large: (378.5, 378.5), extraLarge: (795, 378.5)),
        iPadDesignCanvas(screenSize: (970, 1389), small: (162, 162), medium: (350, 162), large: (350, 350), extraLarge: (726, 350)),
        iPadDesignCanvas(screenSize: (954, 1373), small: (162, 162), medium: (350, 162), large: (350, 350), extraLarge: (726, 350)),
        iPadDesignCanvas(screenSize: (834, 1194), small: (155, 155), medium: (342, 155), large: (342, 342), extraLarge: (715.5, 342)),
        iPadDesignCanvas(screenSize: (834, 1112), small: (150, 150), medium: (327.5, 150), large: (327.5, 327.5), extraLarge: (682, 327.5)),
        // Confirmed on iPad Air 11-inch M2 (iPad14,9) on iPadOS 18.6 and 26.5, and iPad A16 (iPad15,7) on 27.0
        iPadDesignCanvas(screenSize: (820, 1180), small: (155, 155), medium: (342, 155), large: (342, 342), extraLarge: (715.5, 342)),
        iPadDesignCanvas(screenSize: (810, 1080), small: (146, 146), medium: (320.5, 146), large: (320.5, 320.5), extraLarge: (669, 320.5)),
        iPadDesignCanvas(screenSize: (768, 1024), small: (141, 141), medium: (305.5, 141), large: (305.5, 305.5), extraLarge: (634.5, 305.5)),
        // Published by Apple with the same values as 768x1024. The switch this table replaced had no row for it and reached the same values through its default arm.
        iPadDesignCanvas(screenSize: (744, 1133), small: (141, 141), medium: (305.5, 141), large: (305.5, 305.5), extraLarge: (634.5, 305.5))
    ].flatMap { $0 }

    private static func iPadDesignCanvas(
        screenSize: (CGFloat, CGFloat),
        small: (CGFloat, CGFloat),
        medium: (CGFloat, CGFloat),
        large: (CGFloat, CGFloat),
        extraLarge: (CGFloat, CGFloat)
    ) -> [WidgetFrameRecord] {
        iPad(target: .designCanvas, screenSize: screenSize, small: small, medium: medium, large: large, extraLarge: extraLarge)
    }

    /// iPad Home Screen frames, as published by Apple.
    ///
    /// The frame a widget actually occupies on the Home Screen, which the system produces by scaling the larger ``iPadDesignCanvas`` frame down. Measuring a placed `small` widget on a 820x1180 iPad gave 272 pixels, confirming the 136 points published here.
    ///
    /// One row per screen size the same way the canvas table has one, rather than a scale factor applied to the canvas, because the published values are not a constant ratio of it. They range from 0.849 on a 810x1080 iPad to 1 on the Display Zoom rows.
    ///
    /// The system sizes are the only ones with a Home Screen frame. `extraLargePortrait`, the accessory sizes and the Lock Screen `small` frame are measured on the design canvas only, so a Home Screen lookup for those returns nothing.
    ///
    /// > Note: `1192x1590`, `970x1389` and `954x1373` repeat their canvas frames unscaled, which measurement confirms. Those are Display Zoom modes rather than devices, and Apple publishes one frame for each.
    private static let iPadHomeScreen: [WidgetFrameRecord] = [
        iPadHomeScreen(screenSize: (1192, 1590), small: (188, 188), medium: (412, 188), large: (412, 412), extraLarge: (860, 412)),
        iPadHomeScreen(screenSize: (1024, 1366), small: (160, 160), medium: (356, 160), large: (356, 356), extraLarge: (748, 356)),
        iPadHomeScreen(screenSize: (970, 1389), small: (162, 162), medium: (350, 162), large: (350, 350), extraLarge: (726, 350)),
        iPadHomeScreen(screenSize: (954, 1373), small: (162, 162), medium: (350, 162), large: (350, 350), extraLarge: (726, 350)),
        iPadHomeScreen(screenSize: (834, 1194), small: (136, 136), medium: (300, 136), large: (300, 300), extraLarge: (628, 300)),
        iPadHomeScreen(screenSize: (834, 1112), small: (132, 132), medium: (288, 132), large: (288, 288), extraLarge: (600, 288)),
        // The 136 point small frame confirmed by measuring a placed widget at 272 pixels on an iPad Air 11-inch M2 (iPad14,9)
        iPadHomeScreen(screenSize: (820, 1180), small: (136, 136), medium: (300, 136), large: (300, 300), extraLarge: (628, 300)),
        iPadHomeScreen(screenSize: (810, 1080), small: (124, 124), medium: (272, 124), large: (272, 272), extraLarge: (568, 272)),
        iPadHomeScreen(screenSize: (768, 1024), small: (120, 120), medium: (260, 120), large: (260, 260), extraLarge: (540, 260)),
        // Published by Apple with the same values as 768x1024. The switch this table replaced had no row for it and reached the same values through its default arm.
        iPadHomeScreen(screenSize: (744, 1133), small: (120, 120), medium: (260, 120), large: (260, 260), extraLarge: (540, 260))
    ].flatMap { $0 }

    private static func iPadHomeScreen(
        screenSize: (CGFloat, CGFloat),
        small: (CGFloat, CGFloat),
        medium: (CGFloat, CGFloat),
        large: (CGFloat, CGFloat),
        extraLarge: (CGFloat, CGFloat)
    ) -> [WidgetFrameRecord] {
        iPad(target: .homeScreen, screenSize: screenSize, small: small, medium: medium, large: large, extraLarge: extraLarge)
    }

    /// The system frames for one iPad screen size, in whichever target the caller is building.
    private static func iPad(
        target: WidgetTarget,
        screenSize: (CGFloat, CGFloat),
        small: (CGFloat, CGFloat),
        medium: (CGFloat, CGFloat),
        large: (CGFloat, CGFloat),
        extraLarge: (CGFloat, CGFloat)
    ) -> [WidgetFrameRecord] {
        group(
            platform: .pad,
            minMajorOSVersion: 15,
            placement: .homeScreen,
            screenSize: screenSize,
            displayScale: nil,
            target: target,
            frames: [
                .small: small,
                .medium: medium,
                .large: large,
                .extraLarge: extraLarge
            ]
        )
    }

    /// iPad `extraLargePortrait` design canvas frames, measured rather than published. Apple publishes no row for this family on any platform.
    ///
    /// On every iPad the width is identical to `systemMedium` and `systemLarge`, the same rule that holds on iPhone, so this is the same column made taller. On the canvas grid it is two cells wide by three tall, which is what ``iPadPortraitHomeScreen`` relies on.
    ///
    /// > Note: on iPad this family is offered in Today View rather than on the Home Screen grid. WidgetKit's own `WidgetLocation` has no Today View case, so it is recorded against the Home Screen the way every other Today View size is.
    ///
    /// > Note: `834x1112` and `768x1024` have no entry because iPadOS 27 does not run on any iPad reporting those screen sizes.
    private static let iPadPortraitDesignCanvas: [WidgetFrameRecord] = [
        // Measured on iPad Pro 12.9-inch 6th generation with Display Zoom set to More Space, iPadOS 27.0
        iPadPortraitDesignCanvas(screenSize: (1192, 1590), portrait: (824, 1272)),
        // Measured on iPad Pro 13-inch M4, iPadOS 27.0
        iPadPortraitDesignCanvas(screenSize: (1032, 1376), portrait: (757, 1173)),
        // Measured on iPad Pro 12.9-inch 6th generation, iPadOS 27.0
        iPadPortraitDesignCanvas(screenSize: (1024, 1366), portrait: (757, 1173)),
        // Measured on iPad Pro 11-inch 4th generation with Display Zoom set to More Space, iPadOS 27.0
        iPadPortraitDesignCanvas(screenSize: (970, 1389), portrait: (700, 1076)),
        // Measured on iPad Air 11-inch M2 with Display Zoom set to More Space, iPadOS 27.0
        iPadPortraitDesignCanvas(screenSize: (954, 1373), portrait: (700, 1076)),
        // Measured on iPad Pro 11-inch 4th generation, iPadOS 27.0
        iPadPortraitDesignCanvas(screenSize: (834, 1194), portrait: (684, 1058)),
        // Measured on iPad Air 11-inch M2, iPadOS 27.0
        iPadPortraitDesignCanvas(screenSize: (820, 1180), portrait: (684, 1058)),
        // Measured on iPad 9th generation, iPadOS 27.0
        iPadPortraitDesignCanvas(screenSize: (810, 1080), portrait: (641, 989)),
        // Measured on iPad mini 6th generation, iPadOS 27.0
        iPadPortraitDesignCanvas(screenSize: (744, 1133), portrait: (611, 940))
    ].flatMap { $0 }

    private static func iPadPortraitDesignCanvas(
        screenSize: (CGFloat, CGFloat),
        portrait: (CGFloat, CGFloat)
    ) -> [WidgetFrameRecord] {
        group(
            platform: .pad,
            minMajorOSVersion: 27,
            placement: .homeScreen,
            screenSize: screenSize,
            displayScale: nil,
            target: .designCanvas,
            frames: framesFromPixels(displayScale: 2, [.extraLargePortrait: portrait])
        )
    }

    /// iPad `extraLargePortrait` rendered frames, the size the canvas is scaled into.
    ///
    /// Every published Home Screen row is an exact grid: `medium` is two cells plus a gutter, `large` the same square, and `extraLarge` four cells plus three gutters, with no rounding error on any of the ten screen sizes. The canvas rows are the ones that carry a half point, because they are this grid divided by the scale factor. `extraLargePortrait` measures two cells by three on the canvas, so it is two by three here, and every value that produces lands on a whole pixel.
    ///
    /// Confirmed by measurement on a 820x1180 iPad: a placed widget rendered 600x928 pixels, which is the 300x464 predicted here, against a 342x529 design canvas. That is the same 0.8772 scale factor every other size on that iPad uses.
    ///
    /// > Note: `1032x1376` has no row. It has no published Home Screen row of its own to build a grid from, and its canvas frames measured identical to `1024x1366`, so it resolves there by nearest width exactly as its system sizes do.
    ///
    /// The three Display Zoom rows are measured rather than derived, and they came back exactly as the grid predicted: 412x636, 350x538 and 350x538. That is the third independent confirmation of the rule, after the shape check on the canvas and the 600x928 pixel measurement of a placed widget.
    private static let iPadPortraitHomeScreen: [WidgetFrameRecord] = [
        // Display Zoom rows are not scaled: Apple publishes identical canvas and Home Screen system frames for them, so the canvas value is the rendered one.
        iPadPortraitHomeScreen(screenSize: (1192, 1590), portrait: (412, 636)),
        iPadPortraitHomeScreen(screenSize: (970, 1389), portrait: (350, 538)),
        iPadPortraitHomeScreen(screenSize: (954, 1373), portrait: (350, 538)),
        iPadPortraitHomeScreen(screenSize: (1024, 1366), portrait: (356, 552)),
        iPadPortraitHomeScreen(screenSize: (834, 1194), portrait: (300, 464)),
        // Confirmed by measuring a placed widget at 600x928 pixels on an iPad Air 11-inch M4, iPadOS 27.0
        iPadPortraitHomeScreen(screenSize: (820, 1180), portrait: (300, 464)),
        iPadPortraitHomeScreen(screenSize: (810, 1080), portrait: (272, 420)),
        iPadPortraitHomeScreen(screenSize: (744, 1133), portrait: (260, 400))
    ].flatMap { $0 }

    private static func iPadPortraitHomeScreen(
        screenSize: (CGFloat, CGFloat),
        portrait: (CGFloat, CGFloat)
    ) -> [WidgetFrameRecord] {
        group(
            platform: .pad,
            minMajorOSVersion: 27,
            placement: .homeScreen,
            screenSize: screenSize,
            displayScale: nil,
            target: .homeScreen,
            frames: [.extraLargePortrait: portrait]
        )
    }

    /// iPad Lock Screen frames, measured rather than published. Apple's table has no accessory row for iPad at all.
    ///
    /// A `systemSmall` on the iPad Lock Screen is a different size from the same widget on the Home Screen, and on every iPad measured its width is exactly the width of `accessoryRectangular`. The Lock Screen widget column is that wide and a system small is sized to fit it. On a 834x1112 iPad the Lock Screen frame is larger than the Home Screen one rather than smaller.
    ///
    /// > Note: iPad Lock Screen widgets arrived in iPadOS 17 but the earliest measurement is on 18.6, so these apply from 18.
    ///
    /// `1192x1590`, `970x1389` and `954x1373` are Display Zoom modes rather than devices. They are measured, by turning on More Space under Settings > Developer > Display Zoom. Their Lock Screen frames do not follow from the unzoomed ones: a 820x1180 iPad has a 152 point Lock Screen `small` and zooming it to 954x1373 makes that frame *smaller*, at 149, while the other two grow.
    private static let iPadLockScreen: [WidgetFrameRecord] = [
        // Measured on iPad Pro 12.9-inch 6th generation with Display Zoom set to More Space, iPadOS 27.0
        iPadLock(screenSize: (1192, 1590), small: (309, 309), circular: (126, 126), rectangular: (309, 126), inline: (822, 72)),
        // Measured on iPad Pro 11-inch 4th generation with Display Zoom set to More Space, iPadOS 27.0
        iPadLock(screenSize: (970, 1389), small: (305, 305), circular: (124, 124), rectangular: (305, 124), inline: (812, 72)),
        // Measured on iPad Air 11-inch M2 with Display Zoom set to More Space, iPadOS 27.0. Its Lock Screen frames are smaller than the same iPad unzoomed, where they are 152.
        iPadLock(screenSize: (954, 1373), small: (298, 298), circular: (121, 121), rectangular: (298, 121), inline: (796, 72)),
        // Measured on iPad Pro 13-inch M4, iPadOS 26.5
        iPadLock(screenSize: (1032, 1376), small: (301, 301), circular: (120, 120), rectangular: (301, 120), inline: (744, 72)),
        // Measured on iPad Pro 12.9-inch 6th generation, iPadOS 26.5
        iPadLock(screenSize: (1024, 1366), small: (298, 298), circular: (119, 119), rectangular: (298, 119), inline: (748, 72)),
        // Measured on iPad Pro 11-inch 4th generation, iPadOS 26.5
        iPadLock(screenSize: (834, 1194), small: (304, 304), circular: (122, 122), rectangular: (304, 122), inline: (744, 72)),
        // Measured on iPad Air 3rd generation, iPadOS 26.5
        iPadLock(screenSize: (834, 1112), small: (304, 304), circular: (122, 122), rectangular: (304, 122), inline: (744, 72)),
        // Measured on iPad Air 11-inch M2 (iPad14,9), iPadOS 18.6 and 26.5
        iPadLock(screenSize: (820, 1180), small: (304, 304), circular: (126, 126), rectangular: (304, 126), inline: (744, 72)),
        // Measured on iPad 9th generation, iPadOS 26.5
        iPadLock(screenSize: (810, 1080), small: (292, 292), circular: (116, 116), rectangular: (292, 116), inline: (744, 72)),
        // Measured on iPad mini 5th generation, iPadOS 26.5
        iPadLock(screenSize: (768, 1024), small: (271, 271), circular: (106, 106), rectangular: (271, 106), inline: (744, 72)),
        // Measured on iPad mini 6th generation, iPadOS 26.5
        iPadLock(screenSize: (744, 1133), small: (266, 266), circular: (107, 107), rectangular: (266, 107), inline: (744, 72))
    ].flatMap { $0 }

    private static func iPadLock(
        screenSize: (CGFloat, CGFloat),
        small: (CGFloat, CGFloat),
        circular: (CGFloat, CGFloat),
        rectangular: (CGFloat, CGFloat),
        inline: (CGFloat, CGFloat)
    ) -> [WidgetFrameRecord] {
        group(
            platform: .pad,
            minMajorOSVersion: 18,
            placement: .lockScreen,
            screenSize: screenSize,
            /// Every iPad is a 2x display, and no iPad screen size is known to split by scale.
            displayScale: nil,
            target: .designCanvas,
            frames: framesFromPixels(displayScale: 2, [
                .small: small,
                .accessoryCircular: circular,
                .accessoryRectangular: rectangular,
                .accessoryInline: inline
            ])
        )
    }
}
