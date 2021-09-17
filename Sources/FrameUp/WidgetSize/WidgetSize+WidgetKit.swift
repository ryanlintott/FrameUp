//
//  File.swift
//  
//
//  Created by Ryan Lintott on 2021-09-17.
//

import Foundation
import WidgetKit

public extension WidgetSize {
    var widgetFamily: WidgetFamily? {
        switch self {
        case .small: return .systemSmall
        case .medium: return .systemMedium
        case .large: return .systemLarge
        case .extraLarge:
            if #available(iOS 15.0, *) {
                return .systemExtraLarge
            } else {
                return nil
            }
        }
    }
}
