//
//  LegacyFlowContentSizeKey.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-06-11.
//

import SwiftUI

/// Preference key used to pass child view sizes up the hierarchy.
///
/// Used by ``HFlowLegacy`` and ``VFlowLegacy``.
@available(*, deprecated, renamed: "FULayoutSizeKey")
public struct FlowContentSizeKey: PreferenceKey {
    public typealias Value = [Int: CGSize]
    public static let defaultValue: [Int: CGSize] = [:]
    public static func reduce(value: inout Value, nextValue: () -> Value) {
        nextValue().forEach {
            value.updateValue($0.value, forKey: $0.key)
        }
    }
}
