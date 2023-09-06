//
//  Dictionary+extensions.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-09-09.
//

import Foundation

internal extension Dictionary {
    /// Adds a new key/value pair or replaces an existing element with the same key.
    /// - Parameter element: Key-value pair to add.
    mutating func update(with element: (key: Key, value: Value)) {
        updateValue(element.value, forKey: element.key)
    }
}
