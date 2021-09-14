//
//  CellSizeKey.swift
//  SwiftUITextDemo
//
//  Created by Ryan Lintott on 2021-06-11.
//

import SwiftUI

public struct CellSizeKey: PreferenceKey {
    public typealias Value = [Int: CGSize]
    public static let defaultValue: [Int: CGSize] = [:]
    public static func reduce(value: inout Value, nextValue: () -> Value) {
        nextValue().forEach {
            value.updateValue($0.value, forKey: $0.key)
        }
    }
}
