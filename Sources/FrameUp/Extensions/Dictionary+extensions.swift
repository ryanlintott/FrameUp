//
//  File.swift
//  
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

internal extension Dictionary where Dictionary.Key: Comparable {
    /// Creates an array of key value pairs sorted by key.
    func sortedByKey() -> [(key: Key, value: Value)] {
        sorted { $0.key < $1.key }
    }
}
