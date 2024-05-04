//
//  WidgetFamily-extension.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-05-28.
//

#if canImport(WidgetKit)
import SwiftUI
import WidgetKit

@available(watchOS 9, *)
public extension WidgetFamily {
    #if os(iOS)
    /// Supported families for the current device.
    @MainActor
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
        case .accessoryCircular: return .accessoryCircular
        case .accessoryRectangular: return .accessoryRectangular
        case .accessoryInline: return .accessoryInline
        case .accessoryCorner: return nil
        @unknown default: return nil
        }
    }
}
#endif
