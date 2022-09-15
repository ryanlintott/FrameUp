//
//  WidgetFamily-extension.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-05-28.
//

import SwiftUI
import WidgetKit

public extension WidgetFamily {
#if os(iOS)
    /// Supported families for the current device.
    static var supportedFamiliesForCurrentDevice: [WidgetFamily] {
        WidgetSize.supportedSizesForCurrentDevice.compactMap { $0.widgetFamily }
    }
#endif

    /// Equivalent widget size. Only returns nil for unknown values.
    var size: WidgetSize? {
        switch self {
        case .systemSmall: return .small
        case .systemMedium: return .medium
        case .systemLarge: return .large
        case .systemExtraLarge: return .extraLarge
        case .accessoryCircular: return nil
        case .accessoryRectangular: return nil
        case .accessoryInline: return nil
        @unknown default: return nil
        }
    }
}
