//
//  File.swift
//  
//
//  Created by Ryan Lintott on 2022-09-09.
//

import Foundation

internal extension Dictionary where Dictionary.Key: Comparable {
    mutating func update(with element: (key: Key, value: Value)) {
        updateValue(element.value, forKey: element.key)
    }
    
    func sortedByKey() -> [(key: Key, value: Value)] {
        sorted { $0.key < $1.key }
    }
}
