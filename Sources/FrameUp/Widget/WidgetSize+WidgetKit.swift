//
//  WidgetSize+WidgetKit.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-17.
//

#if canImport(WidgetKit)
import Foundation
import WidgetKit

@available(watchOS 9, visionOS 26.0, *)
public extension WidgetSize {
    /// Equivalent widget family. Returns nil when the widget size has no `WidgetFamily` equivalent on the current platform and OS version.
    var widgetFamily: WidgetFamily? {
        switch self {
        case .small:
            #if os(iOS) || os(macOS) || os(visionOS)
            return .systemSmall
            #endif
        case .medium:
            #if os(iOS) || os(macOS) || os(visionOS)
            return .systemMedium
            #endif
        case .large:
            #if os(iOS) || os(macOS) || os(visionOS)
            return .systemLarge
            #endif
        case .extraLarge:
            #if os(iOS) || os(macOS) || os(visionOS)
            if #available(macOS 14.0, *) {
                return .systemExtraLarge
            }
            #endif
        case .extraLargePortrait:
            #if (os(visionOS) && compiler(>=6.2)) || ((os(iOS) || os(macOS)) && compiler(>=6.4))
            if #available(iOS 27.0, macOS 27.0, *) {
                return .systemExtraLargePortrait
            }
            #endif
        case .accessoryRectangular:
            #if os(iOS) || os(watchOS)
            if #available(iOS 16.0, *) {
                return .accessoryRectangular
            }
            #endif
        case .accessoryCircular:
            #if os(iOS) || os(watchOS)
            if #available(iOS 16.0, *) {
                return .accessoryCircular
            }
            #endif
        case .accessoryInline:
            #if os(iOS) || os(watchOS)
            if #available(iOS 16.0, *) {
                return .accessoryInline
            }
            #endif
        case .accessoryCorner:
            /// The only widget family that exists on Apple Watch alone.
            #if os(watchOS)
            return .accessoryCorner
            #endif
        }
        return nil
    }
}
#endif
