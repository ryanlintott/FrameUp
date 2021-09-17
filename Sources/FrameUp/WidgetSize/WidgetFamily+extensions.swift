//
//  WidgetFamily-extension.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-05-28.
//

import SwiftUI
import WidgetKit

extension WidgetFamily {
    public static var supportedFamiliesForCurrentDevice: [WidgetFamily] {
        WidgetSize.supportedSizesForCurrentDevice.compactMap { $0.widgetFamily }
    }
    
    public var size: WidgetSize? {
        switch self {
        case .systemSmall: return .small
        case .systemMedium: return .medium
        case .systemLarge: return .large
        case .systemExtraLarge: return .extraLarge
        @unknown default: return nil
        }
    }
}
