//
//  CellSizeKey.swift
//  SwiftUITextDemo
//
//  Created by Ryan Lintott on 2021-06-11.
//

import SwiftUI

struct CellSizeKey: PreferenceKey {
    typealias Value = [Int: CGSize]
    static let defaultValue: [Int: CGSize] = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        nextValue().forEach {
            value.updateValue($0.value, forKey: $0.key)
        }
    }
}
