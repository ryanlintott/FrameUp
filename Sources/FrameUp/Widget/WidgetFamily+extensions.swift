//
//  WidgetFamily+extensions.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-05-28.
//

#if canImport(WidgetKit)
import SwiftUI
import WidgetKit

@available(watchOS 9, visionOS 26, *)
public extension WidgetFamily {
    #if os(iOS)
    /// Supported families for the current device.
    @preconcurrency @MainActor
    static var supportedFamiliesForCurrentDevice: [WidgetFamily] {
        WidgetSize.supportedSizesForCurrentDevice.compactMap { $0.widgetFamily }
    }
    #endif

    /// Equivalent widget size. Only returns nil for unknown values.
    var size: WidgetSize? {
        switch self {
        #if os(iOS) || os(macOS) || os(visionOS)
        case .systemSmall: .small
        case .systemMedium: .medium
        case .systemLarge: .large
        case .systemExtraLarge: .extraLarge
        #endif
        #if os(visionOS) || (compiler(>=6.4) && (os(iOS) || os(macOS)))
        case .systemExtraLargePortrait: .extraLarge
        #endif
        #if os(iOS) || os(watchOS)
        case .accessoryCircular: .accessoryCircular
        case .accessoryRectangular: .accessoryRectangular
        case .accessoryInline: .accessoryInline
        case .accessoryCorner: nil
        #endif
        @unknown default: nil
        }
    }
}
#endif
