//
//  Dictionary+publicExtensions.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-05-10.
//

import Foundation

public extension Dictionary where Dictionary.Key: Comparable {
    /// Creates an array of key value pairs sorted by key.
    func sortedByKey() -> [(key: Key, value: Value)] {
        sorted { $0.key < $1.key }
    }
}
