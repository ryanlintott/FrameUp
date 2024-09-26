//
//  FULayoutSizeKey.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-05-12.
//

import SwiftUI

/// A preference key used for managing view sizes in an ``FULayout`` view.
public struct FULayoutSizeKey: PreferenceKey {
    public typealias Value = [Int: CGSize]
    public static let defaultValue: [Int: CGSize] = [:]
    public static func reduce(value: inout Value, nextValue: () -> Value) {
        nextValue().forEach {
            value.updateValue($0.value, forKey: $0.key)
        }
    }
}
