//
//  Item.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-09-14.
//

import Foundation

struct Item<Value>: Identifiable {
    var id = UUID()
    var value: Value
}

extension Item: Sendable where Value: Sendable { }
extension Item: Equatable where Value: Equatable { }
extension Item: Hashable where Value: Hashable { }

extension Item<String> {
    static let examples = ["Here", "are", "several", "example", "items", "useful for", "creating", "example layouts", "in", "FrameUp"]
        .map { Item(id: UUID(), value: $0) }
}

extension Array<Item<String>> {
    static let examples = Element.examples
}
