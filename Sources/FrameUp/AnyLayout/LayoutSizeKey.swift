//
//  LayoutSizeKey.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-05-31.
//

import SwiftUI

struct LayoutSizeKey: PreferenceKey {
    public typealias Value = [Int: CGSize]
    public static let defaultValue: [Int: CGSize] = [:]
    public static func reduce(value: inout Value, nextValue: () -> Value) {
        nextValue().forEach {
            value.updateValue($0.value, forKey: $0.key)
        }
    }
}
