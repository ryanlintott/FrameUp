//
//  WidgetSize+WidgetKit.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-17.
//

import Foundation
import WidgetKit

public extension WidgetSize {
    /// Equivalent widget family. Optional as extraLarge will return nil unless running iOS 15.0 or later.
    var widgetFamily: WidgetFamily? {
        switch self {
        case .small: return .systemSmall
        case .medium: return .systemMedium
        case .large: return .systemLarge
        case .extraLarge:
            if #available(iOS 15.0, *) {
                #if os(iOS)
                return .systemExtraLarge
                #else
                return nil
                #endif
            } else {
                return nil
            }
        case .accessoryRectangular:
            if #available(iOS 16.0, *) {
                #if os(iOS)
                return .accessoryRectangular
                #else
                return nil
                #endif
            } else {
                return nil
            }
        case .accessoryCircular:
            if #available(iOS 16.0, *) {
                #if os(iOS)
                return .accessoryCircular
                #else
                return nil
                #endif
            } else {
                return nil
            }
        case .accessoryInline:
            if #available(iOS 16.0, *) {
                #if os(iOS)
                return .accessoryInline
                #else
                return nil
                #endif
            } else {
                return nil
            }
        }
    }
}
