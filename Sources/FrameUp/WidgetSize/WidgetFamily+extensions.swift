//
//  WidgetFamily-extension.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-05-28.
//

import SwiftUI
import WidgetKit

public extension WidgetFamily {
    static var supportedFamiliesForCurrentDevice: [WidgetFamily] {
        WidgetSize.supportedSizesForCurrentDevice.compactMap { $0.widgetFamily }
    }
    
    var size: WidgetSize? {
        switch self {
        case .systemSmall: return .small
        case .systemMedium: return .medium
        case .systemLarge: return .large
        case .systemExtraLarge: return .extraLarge
        @unknown default: return nil
        }
    }
}
