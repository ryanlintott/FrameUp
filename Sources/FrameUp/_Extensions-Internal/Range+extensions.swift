//
//  Range+extensions.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-09.
//

internal extension Range {
    /// The parts of this range that another range doesn't cover, in order: none, one, or two when the other range sits inside this one.
    func subtracting(_ other: Range<Bound>) -> [Range<Bound>] {
        guard other.upperBound > lowerBound, other.lowerBound < upperBound else {
            return [self]
        }

        var remaining: [Range<Bound>] = []
        if other.lowerBound > lowerBound {
            remaining.append(lowerBound..<Swift.min(upperBound, other.lowerBound))
        }
        if other.upperBound < upperBound {
            remaining.append(Swift.max(lowerBound, other.upperBound)..<upperBound)
        }
        return remaining
    }
}
