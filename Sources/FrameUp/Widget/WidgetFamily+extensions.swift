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

    /// Equivalent widget size. May return nil if the size is not known
    var size: WidgetSize? {
        switch self {
        #if os(iOS)
        case .systemSmall: .small
        case .systemMedium: .medium
        case .systemLarge: .large
        case .systemExtraLarge: .extraLarge
        case .accessoryCircular: .accessoryCircular
        case .accessoryRectangular: .accessoryRectangular
        case .accessoryInline: .accessoryInline
        #if compiler(>=6.2)
        case .systemExtraLargePortrait: .extraLargePortrait
        #endif

        #elseif os(macOS)
        case .systemSmall: .small
        case .systemMedium: .medium
        case .systemLarge: .large
        case .systemExtraLarge: .extraLarge
        #if compiler(>=6.2)
        case .systemExtraLargePortrait: .extraLargePortrait
        #endif

        #elseif os(visionOS)
        case .systemSmall: .small
        case .systemMedium: .medium
        case .systemLarge: .large
        case .systemExtraLarge: .extraLarge
        case .systemExtraLargePortrait: .extraLargePortrait
        #if compiler(>=6.4)
        case .accessoryCircular: .accessoryCircular
        case .accessoryRectangular: .accessoryRectangular
        #endif

        #elseif os(watchOS)
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
